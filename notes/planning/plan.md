# Detailed Step-by-Step Build Plan for E-Commerce Microservices Platform

## Phase 1: Project Setup & Architecture Foundation

### Step 1: Initialize Project Structure
- Create a parent Maven/Gradle project for all microservices
- Set up individual Spring Boot modules:
  - `user-service`
  - `product-service`
  - `media-service`
  - `api-gateway`
  - `discovery-service` (Eureka)
- Initialize Angular workspace for frontend
- Set up `.gitignore` and version control

### Step 2: Configure Service Discovery
- Implement **Eureka Discovery Server** in `discovery-service`
  - Add `spring-cloud-starter-netflix-eureka-server` dependency
  - Configure port (default: 8761)
  - Enable `@EnableEurekaServer` annotation
- Configure all microservices as Eureka clients
  - Add `spring-cloud-starter-netflix-eureka-client` dependency
  - Configure application names and Eureka server URL in `application.yml`

### Step 3: Set Up API Gateway
- Implement **Spring Cloud Gateway** in `api-gateway`
  - Add `spring-cloud-starter-gateway` dependency
  - Configure routes for all microservices
  - Add CORS configuration
  - Configure port (e.g., 8080)
- Implement centralized JWT validation filter
- Add rate limiting configuration (optional but recommended)

### Step 4: Configure Kafka Infrastructure
- Set up Kafka broker (using Docker Compose)
- Create topics:
  - `product-created`
  - `product-updated`
  - `product-deleted`
  - `image-uploaded`
  - `user-registered`
- Configure Kafka producers/consumers in relevant services

### Step 5: Database Setup
- Install and configure MongoDB (or use MongoDB Atlas)
- Create separate databases for each service:
  - `user_db`
  - `product_db`
  - `media_db`
- Design collections based on the schema:
  - **User**: id, name, email, password, role, avatar
  - **Product**: id, name, description, price, quantity, userId, imageUrls[]
  - **Media**: id, imagePath, productId, userId, contentType, size

---

## Phase 2: Backend Development - User Service

### Step 6: User Entity & Repository
- Create `User` entity/document with fields:
  - id, name, email, password (hashed), role (CLIENT/SELLER), avatar, createdAt, updatedAt
- Create `UserRepository` extending `MongoRepository`
- Implement custom queries (findByEmail)

### Step 7: Security Configuration
- Add **Spring Security** and **JWT** dependencies
- Implement `BCryptPasswordEncoder` for password hashing
- Create JWT utility class:
  - `generateToken(UserDetails)`
  - `validateToken(String token)`
  - `extractUsername(String token)`
  - `extractClaims(String token)`

### Step 8: Authentication APIs
- **POST /auth/register**
  - Validate input (email format, password strength)
  - Check if email already exists
  - Hash password with BCrypt
  - Save user with selected role (CLIENT/SELLER)
  - Publish `USER_REGISTERED` event to Kafka
  - Return success message (no token yet)
- **POST /auth/login**
  - Validate credentials
  - Generate JWT token with userId and role
  - Return token and user info (exclude password)

### Step 9: Profile Management APIs
- **GET /api/users/me**
  - Extract user from JWT token
  - Return user profile (exclude password)
- **PUT /api/users/me**
  - Update user profile (name, email)
  - Sellers can update avatar (store URL from Media Service)
  - Validate ownership (can only update own profile)
- **PUT /api/users/me/avatar** (optional dedicated endpoint)
  - Accept avatar URL from Media Service
  - Update user's avatar field

### Step 10: User Service Tests
- Unit tests for `UserService` methods
- Integration tests for authentication endpoints
- Test JWT generation and validation
- Test role-based scenarios

---

## Phase 3: Backend Development - Media Service

### Step 11: Media Entity & Storage Configuration
- Create `Media` entity/document:
  - id, fileName, filePath, productId, userId, contentType, size, uploadedAt
- Configure file storage location (e.g., `/uploads` directory or AWS S3)
- Add file storage properties in `application.yml`
- Create `MediaRepository`

### Step 12: File Upload Validation
- Create `FileValidator` component:
  - Check MIME type (accept only image/*)
  - Validate file size (max 2 MB = 2,097,152 bytes)
  - Check file content (magic bytes) to prevent MIME type spoofing
  - Sanitize file names
  - Generate unique file names (UUID + original extension)

### Step 13: Media Upload API
- **POST /api/media/images**
  - Require authentication (JWT)
  - Require SELLER role
  - Accept `MultipartFile` and optional `productId`
  - Validate file (type, size, content)
  - Save file to storage
  - Save metadata to database with userId
  - Publish `IMAGE_UPLOADED` event to Kafka
  - Return media metadata (id, URL, fileName)

### Step 14: Media Retrieval & Management APIs
- **GET /api/media/images/{id}**
  - Serve image file with proper headers
  - Add caching headers (Cache-Control, ETag)
  - Support content negotiation
- **GET /api/media/images** (list seller's images)
  - Filter by authenticated seller's userId
  - Support pagination
- **DELETE /api/media/images/{id}**
  - Require SELLER role
  - Validate ownership (userId matches)
  - Delete file from storage
  - Delete metadata from database
  - Return success message

### Step 15: Media Service Tests
- Unit tests for file validation logic
- Integration tests for upload/download
- Test with various file types and sizes
- Test ownership validation

---

## Phase 4: Backend Development - Product Service

### Step 16: Product Entity & Repository
- Create `Product` entity/document:
  - id, name, description, price, quantity, userId, imageUrls[], createdAt, updatedAt
- Create `ProductRepository` extending `MongoRepository`
- Add custom queries (findByUserId)

### Step 17: Product CRUD APIs - Public Endpoints
- **GET /api/products**
  - Public endpoint (no auth required)
  - Return list of all products
  - Support pagination (page, size parameters)
  - Include image URLs in response
- **GET /api/products/{id}**
  - Public endpoint
  - Return single product by id
  - Return 404 if not found

### Step 18: Product CRUD APIs - Seller Endpoints
- **POST /api/products**
  - Require authentication and SELLER role
  - Validate input (name, price > 0, quantity >= 0)
  - Set userId from JWT token
  - Save product with empty imageUrls[]
  - Publish `PRODUCT_CREATED` event to Kafka
  - Return created product with id
- **PUT /api/products/{id}**
  - Require SELLER role
  - Validate ownership (product.userId == authenticated userId)
  - Update product fields (can update imageUrls)
  - Publish `PRODUCT_UPDATED` event
  - Return updated product
- **DELETE /api/products/{id}**
  - Require SELLER role
  - Validate ownership
  - Delete product
  - Publish `PRODUCT_DELETED` event
  - Optionally trigger deletion of associated images
  - Return success message

### Step 19: Product-Media Integration
- Create endpoint to link images to products:
  - **POST /api/products/{id}/images**
  - Accept array of media IDs
  - Validate that media exists and belongs to seller
  - Add media URLs to product's imageUrls[]
  - Return updated product
- Create Kafka consumer to handle `IMAGE_UPLOADED` events
  - Automatically link images to products if productId is provided

### Step 20: Product Service Tests
- Unit tests for `ProductService` methods
- Integration tests for CRUD operations
- Test ownership validation
- Test role-based access control
- Test Kafka event publishing

---

## Phase 5: Gateway Configuration & Security

### Step 21: Gateway Routing
- Configure routes in API Gateway:
  ```yaml
  /auth/** -> user-service
  /api/users/** -> user-service
  /api/products/** -> product-service
  /api/media/** -> media-service
  ```
- Add path rewriting if needed
- Configure load balancing with Eureka

### Step 22: Gateway Security Filters
- Implement `JwtAuthenticationFilter`:
  - Extract JWT from Authorization header
  - Validate token
  - Extract userId and role
  - Add to request headers for downstream services
- Implement `RoleAuthorizationFilter`:
  - Check required roles for specific paths
  - Block unauthorized requests with 403
- Configure public paths (login, register, GET products)

### Step 23: Cross-Cutting Concerns
- Add CORS configuration in Gateway
- Implement global exception handler
- Add request/response logging filter
- Configure timeout settings
- Add circuit breaker with Resilience4j (optional)

---

## Phase 6: Frontend Development - Angular Setup

### Step 24: Angular Project Initialization
- Create Angular application with routing
- Install dependencies:
  - Angular Material or Bootstrap
  - RxJS operators
  - JWT decode library
- Configure environments (dev, prod) with API URLs
- Set up proxy configuration for local development

### Step 25: Core Module & Services
- Create `CoreModule` (singleton services):
  - `AuthService`: login, register, logout, token management
  - `UserService`: get/update profile
  - `ProductService`: CRUD operations
  - `MediaService`: upload/manage images
- Create `SharedModule` (shared components, pipes, directives)
- Configure `HttpClientModule` with base URL

### Step 26: Authentication Infrastructure
- Create `AuthInterceptor`:
  - Attach JWT token to outgoing requests
  - Add Authorization header
- Create `ErrorInterceptor`:
  - Handle 401 (redirect to login)
  - Handle 403 (show error message)
  - Handle 4xx/5xx errors globally
- Create `AuthGuard`:
  - Check if user is authenticated
  - Redirect to login if not
- Create `RoleGuard`:
  - Check user role (CLIENT/SELLER)
  - Prevent access to seller-only routes

### Step 27: State Management & Models
- Create TypeScript interfaces/models:
  - `User` (id, name, email, role, avatar)
  - `Product` (id, name, description, price, quantity, imageUrls, userId)
  - `Media` (id, fileName, filePath, contentType)
  - `AuthResponse` (token, user)
- Create `SessionService` to manage user session:
  - Store/retrieve token from localStorage
  - Store/retrieve user info
  - Check authentication status
  - Get current user role

---

## Phase 7: Frontend Development - Authentication Pages

### Step 28: Sign-Up Page
- Create `/register` route and component
- Implement reactive form with validations:
  - Name (required, min 2 chars)
  - Email (required, email format)
  - Password (required, min 8 chars, complexity)
  - Confirm password (must match)
  - Role selection (radio buttons: CLIENT / SELLER)
- Add avatar upload for SELLER role:
  - File input with preview
  - Upload to Media Service first
  - Get media URL and include in registration
- Show validation errors inline
- Call `AuthService.register()`
- On success, redirect to login with success message
- Handle errors (email already exists, etc.)

### Step 29: Sign-In Page
- Create `/login` route and component
- Implement reactive form:
  - Email (required, email format)
  - Password (required)
  - Remember me checkbox (optional)
- Call `AuthService.login()`
- Store token and user info in session
- Redirect based on role:
  - SELLER → `/seller/dashboard`
  - CLIENT → `/products`
- Show error messages for invalid credentials

### Step 30: Profile Management
- Create `/profile` route and component
- Display current user info
- Editable form for name and email
- Avatar upload/update for sellers:
  - Current avatar preview
  - Change avatar button
  - Upload to Media Service
  - Update user profile with new URL
- Save changes button
- Handle errors and show success messages

---

## Phase 8: Frontend Development - Seller Features

### Step 31: Seller Dashboard Layout
- Create `/seller` route with child routes
- Implement dashboard layout with navigation:
  - My Products
  - Add Product
  - Media Library
  - Profile
- Show seller info in header
- Add logout button

### Step 32: Product List (Seller View)
- Create `/seller/products` component
- Display seller's products in table/cards:
  - Product image thumbnails
  - Name, price, quantity
  - Actions: Edit, Delete, Manage Images
- Implement pagination
- Add "Add New Product" button
- Implement delete with confirmation dialog
- Show loading states and error messages

### Step 33: Add/Edit Product Form
- Create `/seller/products/new` and `/seller/products/edit/:id` components
- Implement reactive form with validations:
  - Name (required, max 100 chars)
  - Description (optional, max 500 chars)
  - Price (required, number, min 0.01)
  - Quantity (required, number, min 0)
  - Images (optional, can add later)
- Image management section:
  - Upload multiple images
  - Drag & drop support
  - Preview uploaded images
  - Remove images
  - Set primary image
- Client-side validation:
  - File type (images only)
  - File size (max 2 MB per image)
  - Show error for invalid files
- Call `ProductService.create()` or `ProductService.update()`
- On success, redirect to product list
- Handle errors (validation, network, etc.)

### Step 34: Media Library for Sellers
- Create `/seller/media` component
- Display all seller's uploaded images in grid
- Show image details (name, size, upload date)
- Filter: All images / Linked to products / Unlinked
- Actions per image:
  - Preview (modal/lightbox)
  - Delete (with confirmation)
  - Copy URL
- Upload new images section:
  - Multi-file upload
  - Drag & drop zone
  - Progress indicators
  - Validation before upload
- Implement pagination for large collections

---

## Phase 9: Frontend Development - Public Product Pages

### Step 35: Product Listing (Public)
- Create `/products` route (accessible to all)
- Display all products in responsive grid/cards:
  - Primary image
  - Product name
  - Price
  - Brief description (truncated)
- Card click navigates to product detail
- Add pagination
- Show "No products available" message if empty
- Handle loading and error states

### Step 36: Product Detail Page
- Create `/products/:id` route
- Display complete product information:
  - Image gallery with thumbnails and main image
  - Product name, price, quantity
  - Full description
  - Seller information (name, avatar)
- Image gallery features:
  - Click thumbnail to change main image
  - Zoom on hover (optional)
  - Fullscreen view
- Add "Contact Seller" button (optional for future enhancement)
- Show "Out of Stock" if quantity = 0
- Handle product not found (404 page)

---

## Phase 10: UI/UX Polish & Responsive Design

### Step 37: Responsive Design
- Implement mobile-first CSS
- Use Angular Material/Bootstrap grid system
- Test on different screen sizes:
  - Mobile (320px - 767px)
  - Tablet (768px - 1023px)
  - Desktop (1024px+)
- Ensure forms are touch-friendly
- Optimize image sizes for mobile

### Step 38: Loading States & Feedback
- Implement loading spinners:
  - Full-page loader for initial loads
  - Inline loaders for button actions
  - Skeleton screens for content areas
- Toast notifications or snackbars for:
  - Success messages (product created, image uploaded)
  - Error messages (validation, network errors)
  - Info messages (file size exceeded)
- Progress bars for file uploads
- Confirmation dialogs for destructive actions

### Step 39: Form Validation & Error Handling
- Display inline validation errors
- Highlight invalid fields
- Show error summary at form top
- Disable submit button while invalid
- Handle backend validation errors:
  - Map server errors to form fields
  - Display generic errors in alert
- Implement retry mechanisms for network failures

---

## Phase 11: Security Hardening

### Step 40: Backend Security
- Implement HTTPS:
  - Generate SSL certificates (Let's Encrypt)
  - Configure gateway with SSL
  - Force HTTPS redirects
- Password security:
  - Enforce BCrypt with salt rounds = 12
  - Never return password in responses
  - Add password complexity validation
- Input validation:
  - Sanitize all user inputs
  - Use Bean Validation (@Valid, @NotNull, etc.)
  - Validate file content, not just MIME type
- Add security headers in Gateway:
  - X-Content-Type-Options: nosniff
  - X-Frame-Options: DENY
  - X-XSS-Protection: 1; mode=block
  - Content-Security-Policy

### Step 41: Access Control & Ownership
- Product Service ownership checks:
  - Extract userId from JWT
  - Compare with product.userId
  - Return 403 if mismatch
- Media Service ownership checks:
  - Validate userId matches uploader
  - Check if image belongs to seller's product
- Implement audit logging:
  - Log all write operations
  - Include userId, timestamp, action
  - Store in separate collection or Kafka topic

### Step 42: Frontend Security
- Implement XSS prevention:
  - Use Angular's built-in sanitization
  - Avoid innerHTML with user content
  - Sanitize user-generated HTML
- Implement CSRF protection:
  - Use Angular's XSRF-TOKEN handling
  - Configure backend to validate CSRF tokens
- Secure token storage:
  - Store JWT in localStorage or sessionStorage
  - Consider HttpOnly cookies for production
  - Clear token on logout
  - Implement token expiration handling

---

## Phase 12: Testing Strategy

### Step 43: Backend Unit Tests
- Test coverage for all services:
  - UserService: registration, authentication, profile updates
  - ProductService: CRUD operations, ownership validation
  - MediaService: file validation, upload, ownership
- Mock repositories and external dependencies
- Test security configurations
- Test JWT utilities
- Aim for >80% code coverage

### Step 44: Backend Integration Tests
- Test API endpoints with MockMvc or WebTestClient
- Test authentication flows:
  - Successful registration/login
  - Failed authentication
  - Token validation
- Test role-based access:
  - CLIENT cannot create products
  - SELLER cannot modify other's products
- Test file upload scenarios:
  - Valid images
  - Oversized files
  - Invalid MIME types
- Test Kafka integration (with EmbeddedKafka)
- Test MongoDB operations (with embedded MongoDB or Testcontainers)

### Step 45: Frontend Unit Tests
- Test services with HttpClientTestingModule
- Test components:
  - Form validation logic
  - User interactions
  - Conditional rendering
- Test guards and interceptors:
  - AuthGuard redirects when not authenticated
  - AuthInterceptor adds token
  - ErrorInterceptor handles 401/403
- Test pipes and validators
- Aim for >70% code coverage

### Step 46: End-to-End Tests
- Use Cypress or Protractor for E2E tests
- Test critical user flows:
  - **Seller Flow**:
    1. Register as seller with avatar
    2. Login
    3. Create product
    4. Upload product images
    5. Edit product
    6. Delete product
  - **Client Flow**:
    1. Register as client
    2. Login
    3. Browse products
    4. View product details
  - **Security Flow**:
    1. Try to access seller pages as client (should fail)
    2. Try to edit other seller's product (should fail)
    3. Try to upload oversized image (should fail)
- Test responsive design on multiple viewports

---

## Phase 13: DevOps & Deployment

### Step 47: Containerization
- Create Dockerfile for each microservice:
  - Use multi-stage builds
  - Optimize image sizes
  - Set proper working directory
  - Expose correct ports
- Create Dockerfile for Angular app:
  - Build stage with Node
  - Serve with Nginx
  - Copy custom nginx.conf
- Build Docker images and test locally

### Step 48: Docker Compose Setup
- Create `docker-compose.yml` for entire stack:
  - MongoDB service
  - Kafka and Zookeeper services
  - Discovery Service (Eureka)
  - User Service
  - Product Service
  - Media Service
  - API Gateway
  - Angular Frontend (Nginx)
- Configure environment variables
- Set up networks and volumes
- Add health checks for services
- Configure depends_on for service startup order

### Step 49: CI/CD Pipeline
- Set up GitHub Actions or GitLab CI:
  - Build stage: compile and run tests
  - Test stage: unit and integration tests
  - Docker stage: build and push images
  - Deploy stage: deploy to environment
- Configure separate pipelines for:
  - Each microservice
  - Frontend application
- Add code quality checks (SonarQube, ESLint)
- Add security scanning (OWASP Dependency Check)

### Step 50: Deployment
- Choose deployment platform:
  - AWS (ECS, EKS, EC2)
  - Google Cloud (GKE, Cloud Run)
  - Azure (AKS, Container Instances)
  - Heroku (for quick MVP)
- Set up production environment:
  - Configure managed MongoDB (Atlas)
  - Configure managed Kafka (Confluent Cloud, AWS MSK)
  - Set up load balancer
  - Configure auto-scaling
  - Set up SSL certificates
- Configure production secrets and environment variables
- Set up monitoring and logging (next phase)

---

## Phase 14: Observability & Monitoring

### Step 51: Health Checks & Actuator
- Enable Spring Boot Actuator in all services
- Expose endpoints:
  - `/actuator/health` (liveness and readiness probes)
  - `/actuator/info`
  - `/actuator/metrics`
- Configure health checks for dependencies:
  - MongoDB connection
  - Kafka connection
  - Eureka registration
- Implement custom health indicators

### Step 52: Logging
- Configure centralized logging:
  - Use Logback with JSON format
  - Log to stdout for containerized environments
  - Use correlation IDs for request tracing
- Set up log aggregation:
  - ELK Stack (Elasticsearch, Logstack, Kibana)
  - Or Grafana Loki
  - Or cloud-native solutions (CloudWatch, Stackdriver)
- Configure log levels per environment
- Log important events (auth, errors, ownership violations)

### Step 53: Monitoring & Metrics
- Set up Prometheus to scrape metrics from Actuator
- Configure Grafana dashboards:
  - Service health and uptime
  - Request rates and latencies
  - Error rates
  - JVM metrics (heap, threads)
  - Database connection pool metrics
  - Kafka consumer lag
- Set up alerts for:
  - Service down
  - High error rates
  - High latency
  - Database connection issues

### Step 54: Distributed Tracing
- Implement Spring Cloud Sleuth:
  - Add trace and span IDs to logs
  - Propagate trace context across services
- Set up Zipkin or Jaeger:
  - Collect and visualize traces
  - Identify bottlenecks
  - Debug cross-service issues
- Configure sampling rate for production

---

## Phase 15: Documentation & Finalization

### Step 55: API Documentation
- Generate API documentation with Swagger/OpenAPI:
  - Add `springdoc-openapi` dependency
  - Annotate controllers with @Operation, @ApiResponse
  - Configure security schemes (JWT)
  - Expose Swagger UI at `/swagger-ui.html`
- Document API endpoints for each service:
  - Request/response examples
  - Authentication requirements
  - Error responses
  - Status codes

### Step 56: Code Documentation
- Add JavaDoc comments to classes and methods
- Add TSDoc comments to TypeScript code
- Document complex algorithms
- Add README.md in each service:
  - Service purpose
  - Dependencies
  - Configuration
  - How to run locally
  - Environment variables

### Step 57: Comprehensive README
- Create main `README.md` in project root:
  - **Project Overview**: description, features
  - **Architecture Diagram**: with all services
  - **Technologies Used**: list all frameworks, tools
  - **Prerequisites**: Java, Node, Docker, MongoDB, Kafka
  - **Setup Instructions**:
    - Clone repository
    - Configure environment variables
    - Run with Docker Compose
    - Access URLs for each service
  - **Development Guide**:
    - Project structure
    - How to add new features
    - Coding conventions
  - **Testing**: how to run tests
  - **Deployment**: deployment instructions
  - **API Documentation**: link to Swagger UI
  - **Troubleshooting**: common issues and solutions
  - **Contributing**: guidelines (if open source)
  - **License**: MIT, Apache, etc.

### Step 58: Database Seed Data
- Create seed scripts for development:
  - Sample users (seller and client accounts)
  - Sample products with images
  - Test data for easier development
- Create script to reset database
- Document default credentials clearly

### Step 59: Final Testing & QA
- Perform comprehensive testing:
  - All user flows work end-to-end
  - All validations work correctly
  - All error scenarios handled gracefully
  - Security measures are effective
  - Performance is acceptable
- Cross-browser testing (Chrome, Firefox, Safari, Edge)
- Mobile device testing
- Load testing with JMeter or Gatling
- Security testing (OWASP Top 10)
- Fix any identified issues

### Step 60: Project Handover
- Prepare presentation/demo:
  - Show registration and login
  - Show seller creating products and uploading images
  - Show client browsing products
  - Show security features (role restrictions)
  - Show monitoring dashboards
- Create video walkthrough (optional)
- Document known limitations and future enhancements
- Create issue backlog for improvements

---

## Time Estimation by Phase

1. **Phase 1** (Setup): 2-3 days
2. **Phase 2** (User Service): 3-4 days
3. **Phase 3** (Media Service): 3-4 days
4. **Phase 4** (Product Service): 3-4 days
5. **Phase 5** (Gateway): 2-3 days
6. **Phase 6** (Angular Setup): 2 days
7. **Phase 7** (Auth Pages): 2-3 days
8. **Phase 8** (Seller Features): 4-5 days
9. **Phase 9** (Public Pages): 2-3 days
10. **Phase 10** (UI/UX): 2-3 days
11. **Phase 11** (Security): 2-3 days
12. **Phase 12** (Testing): 4-5 days
13. **Phase 13** (DevOps): 3-4 days
14. **Phase 14** (Observability): 2-3 days
15. **Phase 15** (Documentation): 2-3 days

**Total Estimated Time: 6-8 weeks** (assuming 1 full-time developer)

---

## Key Success Factors

1. ✅ **Proper service boundaries**: Keep services independent and cohesive
2. ✅ **Security first**: Implement authentication and authorization from the start
3. ✅ **Iterative development**: Build one service at a time, test thoroughly
4. ✅ **Consistent patterns**: Use same patterns across all services
5. ✅ **Good documentation**: Document as you build, not at the end
6. ✅ **Version control**: Commit frequently with meaningful messages
7. ✅ **Testing discipline**: Write tests alongside code
8. ✅ **Performance consideration**: Monitor and optimize early

---

## Technology Stack Summary

### Backend
- **Language**: Java 17+
- **Framework**: Spring Boot 3.x
- **API Gateway**: Spring Cloud Gateway
- **Service Discovery**: Netflix Eureka
- **Security**: Spring Security + JWT/OAuth2
- **Database**: MongoDB
- **Message Broker**: Apache Kafka
- **Testing**: JUnit 5, Mockito, Testcontainers
- **Build Tool**: Maven or Gradle

### Frontend
- **Framework**: Angular 15+
- **Language**: TypeScript
- **UI Library**: Angular Material or Bootstrap
- **State Management**: RxJS
- **HTTP Client**: Angular HttpClient
- **Testing**: Jasmine, Karma, Cypress

### DevOps
- **Containerization**: Docker
- **Orchestration**: Docker Compose (dev), Kubernetes (prod)
- **CI/CD**: GitHub Actions or GitLab CI
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack or Grafana Loki
- **Tracing**: Spring Cloud Sleuth + Zipkin/Jaeger

### Development Tools
- **IDE**: IntelliJ IDEA or VS Code
- **API Testing**: Postman or Insomnia
- **Version Control**: Git
- **API Documentation**: Swagger/OpenAPI

This plan integrates requirements from both instruction files and provides a clear path from initial setup to production deployment. Follow these steps sequentially for best results!
