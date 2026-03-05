# Phase 5 Explained - Gateway Configuration & Security

This document explains all concepts from Phase 5 (API Gateway and Security) in beginner-friendly language.

---

## Overview: What is Phase 5 About?

**Simple explanation:** Now that we have individual services (User, Product, Media), we need:
- A single entry point for all requests (Gateway)
- Central security enforcement (JWT validation)
- Request routing to correct services
- Cross-cutting concerns (CORS, logging, rate limiting)

Think of the Gateway as a "smart receptionist" that directs visitors and enforces security.

---

## Step 21: Gateway Routing

### What is Routing?

**Simple explanation:** Deciding where to send requests based on URL.

**Example:**
```
Request: GET /api/products/123
Gateway thinks: "This starts with /api/products, send to Product Service"

Request: POST /api/media/images
Gateway thinks: "This starts with /api/media, send to Media Service"
```

### Route Configuration

**application.yml in API Gateway:**
```yaml
spring:
  cloud:
    gateway:
      routes:
        # Route 1: Authentication endpoints
        - id: auth-service
          uri: lb://USER-SERVICE        # lb = load balanced via Eureka
          predicates:
            - Path=/auth/**              # Match URLs starting with /auth/
          filters:
            - RewritePath=/auth/(?<segment>.*), /auth/${segment}
        
        # Route 2: User management
        - id: user-service
          uri: lb://USER-SERVICE
          predicates:
            - Path=/api/users/**
          filters:
            - JwtAuthenticationFilter    # Custom filter (explained later)
        
        # Route 3: Product endpoints
        - id: product-service
          uri: lb://PRODUCT-SERVICE
          predicates:
            - Path=/api/products/**
          filters:
            - JwtAuthenticationFilter
        
        # Route 4: Media endpoints
        - id: media-service
          uri: lb://MEDIA-SERVICE
          predicates:
            - Path=/api/media/**
          filters:
            - JwtAuthenticationFilter
```

### Configuration Breakdown

**id**: Unique name for this route
- Just for identification
- Example: "user-service", "product-service"

**uri**: Where to send requests
- `lb://USER-SERVICE` means:
  - `lb://` → use load balancer
  - `USER-SERVICE` → service name in Eureka
- Gateway asks Eureka: "Where is USER-SERVICE?"
- Eureka responds: "It's at http://localhost:8081"

**predicates**: Conditions to match requests
- `Path=/auth/**` → matches any URL starting with /auth/
  - `/auth/login` ✓
  - `/auth/register` ✓
  - `/products/123` ✗

**filters**: Operations to apply to requests
- Can modify requests/responses
- Can add authentication
- Can log, rate limit, etc.

### Path Patterns

**Wildcards:**
- `/auth/*` → matches one segment
  - `/auth/login` ✓
  - `/auth/register` ✓
  - `/auth/user/profile` ✗ (two segments after /auth/)

- `/auth/**` → matches multiple segments
  - `/auth/login` ✓
  - `/auth/user/profile` ✓
  - `/auth/user/profile/edit` ✓

### Load Balancing with Eureka

**Without Eureka:**
```yaml
uri: http://localhost:8081  # Hardcoded address
```
Problems:
- Can't scale (what if we have 3 instances?)
- Can't handle failures (what if this instance crashes?)
- Can't deploy to different servers

**With Eureka:**
```yaml
uri: lb://USER-SERVICE
```
Benefits:
- Gateway discovers service location automatically
- Multiple instances? Gateway distributes requests
- Instance crashes? Gateway routes to healthy instances
- Location changes? No config updates needed

**How it works:**
```
1. User Service starts → registers with Eureka: "I'm USER-SERVICE at localhost:8081"
2. Another instance starts → "I'm USER-SERVICE at localhost:8082"
3. Gateway needs USER-SERVICE → asks Eureka
4. Eureka responds: "USER-SERVICE has 2 instances: 8081 and 8082"
5. Gateway picks one (round-robin or other algorithm)
```

### Path Rewriting

**Problem:** External URL doesn't match internal URL

**Example:**
- External: `GET /auth/login`
- Internal: `GET /api/auth/login`

**Solution: RewritePath filter**
```yaml
filters:
  - RewritePath=/auth/(?<segment>.*), /api/auth/${segment}
```

**How it works:**
- `(?<segment>.*)` → captures everything after /auth/
- `${segment}` → uses captured value
- `/auth/login` becomes `/api/auth/login`

---

## Step 22: Gateway Security Filters

### What are Filters?

**Simple explanation:** Like checkpoints that requests pass through.

**Example flow:**
```
Request → Gateway → Filter 1 (CORS) → Filter 2 (JWT) → Filter 3 (Logging) → Service
```

Each filter can:
- Inspect the request
- Modify the request
- Block the request
- Add response headers

### JWT Authentication Filter

**Purpose:** Validate JWT token and extract user information.

**Custom Filter Implementation:**
```java
@Component
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {
    
    @Autowired
    private JwtUtil jwtUtil;
    
    // List of public paths (no authentication needed)
    private static final List<String> PUBLIC_PATHS = Arrays.asList(
        "/auth/login",
        "/auth/register",
        "/api/products"  // GET products is public
    );
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getPath().toString();
        String method = request.getMethod().toString();
        
        // 1. Check if path is public
        if (isPublicPath(path, method)) {
            return chain.filter(exchange);  // Skip authentication
        }
        
        // 2. Extract token from Authorization header
        String token = extractToken(request);
        
        if (token == null) {
            return onError(exchange, "Missing or invalid Authorization header", HttpStatus.UNAUTHORIZED);
        }
        
        // 3. Validate token
        try {
            if (!jwtUtil.validateToken(token)) {
                return onError(exchange, "Invalid or expired token", HttpStatus.UNAUTHORIZED);
            }
            
            // 4. Extract user information from token
            String userId = jwtUtil.extractUserId(token);
            String role = jwtUtil.extractRole(token);
            
            // 5. Add user info to request headers for downstream services
            ServerHttpRequest modifiedRequest = request.mutate()
                .header("X-User-Id", userId)
                .header("X-User-Role", role)
                .build();
            
            ServerWebExchange modifiedExchange = exchange.mutate()
                .request(modifiedRequest)
                .build();
            
            // 6. Continue to next filter or service
            return chain.filter(modifiedExchange);
            
        } catch (Exception e) {
            return onError(exchange, "Authentication failed", HttpStatus.UNAUTHORIZED);
        }
    }
    
    private boolean isPublicPath(String path, String method) {
        // /auth/login and /auth/register are always public
        if (path.startsWith("/auth/")) {
            return true;
        }
        
        // GET /api/products/* is public (viewing products)
        if (path.startsWith("/api/products") && method.equals("GET")) {
            return true;
        }
        
        return false;
    }
    
    private String extractToken(ServerHttpRequest request) {
        List<String> headers = request.getHeaders().get("Authorization");
        
        if (headers != null && !headers.isEmpty()) {
            String authHeader = headers.get(0);
            
            // Format: "Bearer eyJhbGciOi..."
            if (authHeader.startsWith("Bearer ")) {
                return authHeader.substring(7);  // Remove "Bearer " prefix
            }
        }
        
        return null;
    }
    
    private Mono<Void> onError(ServerWebExchange exchange, String message, HttpStatus status) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(status);
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        
        String errorJson = "{\"error\":\"" + message + "\"}";
        DataBuffer buffer = response.bufferFactory().wrap(errorJson.getBytes());
        
        return response.writeWith(Mono.just(buffer));
    }
    
    @Override
    public int getOrder() {
        return -100;  // Execute early (lower number = higher priority)
    }
}
```

### Filter Explained Step-by-Step

**Step 1: Check if public path**
```java
if (isPublicPath(path, method)) {
    return chain.filter(exchange);
}
```
- Some endpoints don't need authentication (login, register, viewing products)
- If public, skip authentication and continue

**Step 2: Extract token**
```java
String token = extractToken(request);
```
- Look for "Authorization" header
- Expected format: `Authorization: Bearer <token>`
- Extract token part (everything after "Bearer ")

**Step 3: Validate token**
```java
if (!jwtUtil.validateToken(token)) {
    return onError(exchange, "Invalid token", UNAUTHORIZED);
}
```
- Check signature (hasn't been tampered with)
- Check expiration (not expired)
- Return 401 if invalid

**Step 4: Extract user information**
```java
String userId = jwtUtil.extractUserId(token);
String role = jwtUtil.extractRole(token);
```
- Decode token payload
- Get userId and role embedded in token

**Step 5: Add to request headers**
```java
ServerHttpRequest modifiedRequest = request.mutate()
    .header("X-User-Id", userId)
    .header("X-User-Role", role)
    .build();
```
- Add user info as headers
- Downstream services can read these headers
- Services don't need to validate JWT themselves

**Downstream service reads headers:**
```java
@GetMapping("/me")
public User getCurrentUser(@RequestHeader("X-User-Id") String userId) {
    return userRepository.findById(userId);
}
```

### Role Authorization Filter

**Purpose:** Check if user has required role for specific endpoints.

```java
@Component
public class RoleAuthorizationFilter implements GlobalFilter, Ordered {
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getPath().toString();
        String method = request.getMethod().toString();
        String role = request.getHeaders().getFirst("X-User-Role");
        
        // Check role requirements
        if (requiresSeller(path, method) && !"SELLER".equals(role)) {
            return onError(exchange, "Seller role required", HttpStatus.FORBIDDEN);
        }
        
        return chain.filter(exchange);
    }
    
    private boolean requiresSeller(String path, String method) {
        // POST/PUT/DELETE products require SELLER role
        if (path.startsWith("/api/products") && !method.equals("GET")) {
            return true;
        }
        
        // All media operations require SELLER
        if (path.startsWith("/api/media")) {
            return true;
        }
        
        return false;
    }
    
    @Override
    public int getOrder() {
        return -90;  // After JWT filter (-100), before other filters
    }
}
```

---

## Step 23: Cross-Cutting Concerns

### CORS Configuration

**What is CORS?** Browser security feature that controls cross-origin requests.

**Problem without CORS:**
```
Your Angular app runs on: http://localhost:4200
Your API runs on: http://localhost:8080

Browser blocks requests from 4200 to 8080 (different origins)
```

**Solution: Configure CORS in Gateway**
```java
@Configuration
public class CorsConfig {
    
    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration config = new CorsConfiguration();
        
        // Allow requests from your frontend
        config.addAllowedOrigin("http://localhost:4200");      // Development
        config.addAllowedOrigin("https://yourdomain.com");     // Production
        
        // Allow all HTTP methods
        config.addAllowedMethod("GET");
        config.addAllowedMethod("POST");
        config.addAllowedMethod("PUT");
        config.addAllowedMethod("DELETE");
        config.addAllowedMethod("OPTIONS");
        
        // Allow all headers
        config.addAllowedHeader("*");
        
        // Allow credentials (cookies, authorization headers)
        config.setAllowCredentials(true);
        
        // How long browser can cache CORS response
        config.setMaxAge(3600L);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);  // Apply to all paths
        
        return new CorsWebFilter(source);
    }
}
```

**CORS Headers in Response:**
```
Access-Control-Allow-Origin: http://localhost:4200
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
Access-Control-Allow-Headers: *
Access-Control-Allow-Credentials: true
```

### Global Exception Handler

**Purpose:** Handle errors consistently across all services.

```java
@Component
public class GlobalExceptionHandler implements ErrorWebExceptionHandler {
    
    @Override
    public Mono<Void> handle(ServerWebExchange exchange, Throwable ex) {
        ServerHttpResponse response = exchange.getResponse();
        response.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        
        HttpStatus status;
        String message;
        
        // Determine status code based on exception type
        if (ex instanceof ResponseStatusException) {
            ResponseStatusException rse = (ResponseStatusException) ex;
            status = rse.getStatus();
            message = rse.getReason();
        } else if (ex instanceof UnauthorizedException) {
            status = HttpStatus.UNAUTHORIZED;
            message = ex.getMessage();
        } else if (ex instanceof ForbiddenException) {
            status = HttpStatus.FORBIDDEN;
            message = ex.getMessage();
        } else {
            status = HttpStatus.INTERNAL_SERVER_ERROR;
            message = "An unexpected error occurred";
            // Log the actual error for debugging
            logger.error("Unhandled exception", ex);
        }
        
        response.setStatusCode(status);
        
        // Create error response
        ErrorResponse errorResponse = new ErrorResponse(
            status.value(),
            message,
            LocalDateTime.now()
        );
        
        byte[] bytes = new ObjectMapper().writeValueAsBytes(errorResponse);
        DataBuffer buffer = response.bufferFactory().wrap(bytes);
        
        return response.writeWith(Mono.just(buffer));
    }
}
```

**Error Response Format:**
```json
{
  "status": 401,
  "message": "Invalid or expired token",
  "timestamp": "2026-03-05T14:30:00Z"
}
```

### Request/Response Logging

**Purpose:** Log all requests for debugging and monitoring.

```java
@Component
public class LoggingFilter implements GlobalFilter, Ordered {
    
    private static final Logger logger = LoggerFactory.getLogger(LoggingFilter.class);
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        
        // Log request
        logger.info("Incoming request: {} {} from {}",
            request.getMethod(),
            request.getPath(),
            request.getRemoteAddress());
        
        long startTime = System.currentTimeMillis();
        
        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            long duration = System.currentTimeMillis() - startTime;
            ServerHttpResponse response = exchange.getResponse();
            
            // Log response
            logger.info("Completed request: {} {} - Status: {} - Duration: {}ms",
                request.getMethod(),
                request.getPath(),
                response.getStatusCode(),
                duration);
        }));
    }
    
    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;  // Log first
    }
}
```

**Log Output:**
```
INFO: Incoming request: GET /api/products from /127.0.0.1:54321
INFO: Completed request: GET /api/products - Status: 200 OK - Duration: 45ms
```

### Timeout Configuration

**Purpose:** Prevent hanging requests that never complete.

```yaml
spring:
  cloud:
    gateway:
      httpclient:
        connect-timeout: 5000        # 5 seconds to connect
        response-timeout: 30s        # 30 seconds for response
      
      routes:
        - id: user-service
          uri: lb://USER-SERVICE
          predicates:
            - Path=/api/users/**
          filters:
            - name: CircuitBreaker
              args:
                name: userServiceCircuitBreaker
                fallbackUri: forward:/fallback/user
```

**Why timeouts?**
- Prevent infinite waiting
- Free up resources
- Return error to user promptly

### Circuit Breaker (Optional but Recommended)

**What it is:** Prevents cascading failures when a service is down.

**Analogy:** Like an electrical circuit breaker in your home:
- Detects problems (short circuit)
- Opens circuit (cuts power)
- Prevents damage (house fire)

**In software:**
- Detects service failures
- Stops sending requests to failing service
- Returns fallback response
- Attempts recovery after timeout

**Configuration with Resilience4j:**
```java
@Configuration
public class CircuitBreakerConfig {
    
    @Bean
    public Customizer<ReactiveResilience4JCircuitBreakerFactory> defaultCustomizer() {
        return factory -> factory.configureDefault(id -> new Resilience4JConfigBuilder(id)
            .circuitBreakerConfig(CircuitBreakerConfig.custom()
                .slidingWindowSize(10)                    // Track last 10 requests
                .failureRateThreshold(50)                 // Open if 50% fail
                .waitDurationInOpenState(Duration.ofSeconds(30))  // Wait 30s before retry
                .permittedNumberOfCallsInHalfOpenState(3) // Try 3 requests when recovering
                .build())
            .timeLimiterConfig(TimeLimiterConfig.custom()
                .timeoutDuration(Duration.ofSeconds(5))   // 5 second timeout
                .build())
            .build());
    }
}
```

**Fallback Endpoint:**
```java
@RestController
@RequestMapping("/fallback")
public class FallbackController {
    
    @GetMapping("/user")
    public ResponseEntity<?> userServiceFallback() {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(new ErrorResponse("User service is temporarily unavailable. Please try again later."));
    }
}
```

**Circuit Breaker States:**
```
CLOSED (normal) → Requests pass through
    ↓ (too many failures)
OPEN (failing) → All requests fail immediately with fallback
    ↓ (after wait time)
HALF_OPEN (testing) → Allow few requests to test recovery
    ↓ (if successful)
CLOSED (recovered) → Back to normal
```

---

## Key Takeaways

### Gateway Responsibilities
1. ✅ Single entry point for all requests
2. ✅ Route requests to appropriate services
3. ✅ Validate JWT tokens centrally
4. ✅ Enforce role-based access
5. ✅ Handle CORS
6. ✅ Log requests
7. ✅ Handle timeouts and circuit breaking

### Security Layers
1. **Authentication** (JWT Filter): Who are you?
2. **Authorization** (Role Filter): What can you do?
3. **Ownership** (In services): Is this yours?

### Filter Execution Order
```
1. Logging Filter (HIGHEST_PRECEDENCE)
2. CORS Filter
3. JWT Authentication Filter (-100)
4. Role Authorization Filter (-90)
5. Circuit Breaker
6. Route to Service
7. Logging Filter (response timing)
```

### Common Issues
❌ Wrong filter order (role check before auth check)
❌ Missing CORS config (browser blocks requests)
❌ Not handling OPTIONS requests (CORS preflight)
❌ Hardcoding service URLs (not scalable)
❌ No timeout config (hanging requests)

---

## Next Steps

After completing Phase 5, you should have:
✅ API Gateway routing all requests
✅ Central JWT validation
✅ Role-based access control
✅ CORS properly configured
✅ Request logging
✅ Error handling
✅ Circuit breaker for resilience

**Move to Phase 6:** Frontend development with Angular
