# Phase 2 Explained - Backend Development: User Service

This document explains all concepts from Phase 2 (User Service development) in beginner-friendly language.

---

## Overview: What is the User Service?

**Simple explanation:** The User Service is the part of your application that handles everything related to users:
- Creating new accounts (registration)
- Logging in
- Managing user profiles
- Checking permissions (is this user a client or seller?)

Think of it as the "identity management department" of your e-commerce platform.

---

## Step 6: User Entity & Repository

### Entity (in programming)
**What it is:** A class that represents data you want to store in a database.

**Simple explanation:** An entity is like a blueprint or template for creating objects.

**Real-world analogy:** Think of a form at the doctor's office:
- The blank form is the **Entity** (User class)
- Each filled form is an **Object** (specific user like "John Doe")

**User Entity example:**
```java
@Document(collection = "users")  // Store in "users" collection
public class User {
    @Id
    private String id;              // Unique identifier
    private String name;            // User's name
    private String email;           // Email address
    private String password;        // Hashed password
    private Role role;              // CLIENT or SELLER
    private String avatar;          // Profile picture URL
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Getters and setters...
}
```

### Fields Explained

**id**: Unique identifier
- Like a social security number - unique for each user
- MongoDB generates this automatically
- Example: `"507f1f77bcf86cd799439011"`

**name**: User's full name
- Example: `"Jane Doe"`
- Used for display purposes

**email**: Email address
- Example: `"jane@example.com"`
- Must be unique (no two users can have same email)
- Used for login

**password**: Encrypted password
- **Never store plain text passwords!**
- Stored as a hash: `"$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"`
- Even if database is stolen, passwords are safe

**role**: Type of user (Enum)
```java
public enum Role {
    CLIENT,   // Regular customer who browses and buys
    SELLER    // Business user who can create/sell products
}
```

**avatar**: Profile picture URL
- Example: `"https://example.com/avatars/jane-avatar.jpg"`
- Optional (can be null)
- For sellers, displayed with their products

**createdAt / updatedAt**: Timestamps
- Track when user registered and last updated profile
- Useful for analytics and auditing

### Repository Pattern
**What it is:** A layer between your business logic and database that handles data operations.

**Simple explanation:** Think of a librarian:
- You don't go into the storage room to find books yourself
- You ask the librarian (Repository) to find, add, or remove books
- The librarian knows how to organize and retrieve books efficiently

**Without Repository:**
```java
// You'd have to write database queries manually everywhere
db.collection("users").find({email: "jane@example.com"});
```

**With Repository:**
```java
// Simple, readable method calls
User user = userRepository.findByEmail("jane@example.com");
```

### MongoRepository
**What it is:** Spring Data provides ready-made repository with common operations.

**Simple explanation:** Like a template with pre-built features. You get these methods automatically:
- `save(user)` - Save or update a user
- `findById(id)` - Find user by ID
- `findAll()` - Get all users
- `deleteById(id)` - Delete a user
- `count()` - Count total users

**Creating a Repository:**
```java
public interface UserRepository extends MongoRepository<User, String> {
    // MongoRepository gives you basic CRUD operations
    
    // You can add custom query methods:
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    List<User> findByRole(Role role);
}
```

**How Spring Magic Works:**
- You just **declare** the method name
- Spring **automatically generates** the query based on the name
- `findByEmail` → Spring knows to search by email field
- `existsByEmail` → Spring knows to check if email exists

---

## Step 7: Security Configuration

### Spring Security
**What it is:** A powerful framework for handling authentication and authorization.

**Simple explanation:** Like a security guard for your application:
- **Authentication:** Verifying who you are (login)
- **Authorization:** Checking what you're allowed to do (permissions)

**Without Security:**
- Anyone could access any endpoint
- Passwords stored in plain text
- No way to verify user identity

**With Spring Security:**
- Protected endpoints (must be logged in)
- Passwords encrypted
- Role-based permissions (sellers can create products, clients cannot)

### BCrypt Password Encoder
**What it is:** A one-way encryption algorithm for passwords.

**Simple explanation:** Like a paper shredder:
- You can put paper in (hash password)
- You can't reconstruct the original paper (can't reverse the hash)
- But you can shred another paper and compare the shreds (verify password)

**How it works:**

1. **Registration** - User creates account with password "MySecret123":
   ```java
   String plainPassword = "MySecret123";
   String hashedPassword = bcrypt.encode(plainPassword);
   // Result: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"
   // Store this in database
   ```

2. **Login** - User tries to login with password "MySecret123":
   ```java
   String inputPassword = "MySecret123";
   String storedHash = "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy";
   
   boolean matches = bcrypt.matches(inputPassword, storedHash);
   // Returns: true (passwords match!)
   ```

**Why BCrypt?**
- **Salt:** Adds random data to each password (same password creates different hashes)
- **Slow:** Intentionally slow to prevent brute-force attacks
- **Industry standard:** Widely used and trusted

**Configuration:**
```java
@Configuration
public class SecurityConfig {
    
    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);  // 12 = cost factor (higher = more secure, slower)
    }
}
```

### JWT (JSON Web Token) - Deep Dive

**What it is:** A compact, self-contained way to securely transmit information.

**Simple explanation:** Like a theme park wristband:
- Buy ticket at entrance (login)
- Get wristband with encoded info (JWT)
- Show wristband at each ride (authenticated requests)
- Staff can verify wristband without calling entrance (stateless)

### JWT Structure

A JWT looks like this:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIxMjM0NTYiLCJyb2xlIjoiU0VMTEVSIiwiZXhwIjoxNjQwOTk1MjAwfQ.ZCKwwH5a6eVYHJCN3hfZRkRy0XQz5u0dJkjF6OxZYNw
```

Broken down:
```
HEADER.PAYLOAD.SIGNATURE
```

**1. Header** (red): `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`
Decoded:
```json
{
  "alg": "HS256",      // Algorithm used
  "typ": "JWT"         // Token type
}
```

**2. Payload** (purple): `eyJ1c2VySWQiOiIxMjM0NTYiLCJyb2xlIjoiU0VMTEVSIiwiZXhwIjoxNjQwOTk1MjAwfQ`
Decoded:
```json
{
  "userId": "123456",
  "role": "SELLER",
  "exp": 1640995200   // Expiration timestamp
}
```

**3. Signature** (blue): `ZCKwwH5a6eVYHJCN3hfZRkRy0XQz5u0dJkjF6OxZYNw`
- Hash of (header + payload + secret key)
- Proves token hasn't been tampered with

### JWT Utility Class

**Purpose:** Centralize all JWT operations in one place.

```java
@Component
public class JwtUtil {
    
    @Value("${jwt.secret}")
    private String SECRET_KEY;  // Secret key from config (keep safe!)
    
    // Generate token when user logs in
    public String generateToken(User user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.getId());
        claims.put("role", user.getRole());
        
        return Jwts.builder()
            .setClaims(claims)
            .setSubject(user.getEmail())
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + 1000 * 60 * 60 * 24))  // 24 hours
            .signWith(SignatureAlgorithm.HS256, SECRET_KEY)
            .compact();
    }
    
    // Extract username from token
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }
    
    // Extract userId from token
    public String extractUserId(String token) {
        return extractAllClaims(token).get("userId", String.class);
    }
    
    // Check if token is valid
    public boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }
    
    // Check if token is expired
    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }
    
    // Helper methods...
}
```

**Key Methods Explained:**

**generateToken(User)**: Creates a new JWT
- Called when user logs in successfully
- Embeds userId and role in token
- Sets expiration time (24 hours)
- Signs with secret key

**validateToken(String, UserDetails)**: Verifies JWT
- Called on every protected request
- Checks if token is expired
- Verifies signature hasn't been tampered with
- Returns true/false

**extractUsername/UserId**: Gets data from token
- Decode token and read embedded information
- No database call needed!

---

## Step 8: Authentication APIs

### POST /auth/register - Registration Endpoint

**Purpose:** Create a new user account.

**Flow:**
```
User fills form → Frontend sends data → Backend validates → Save to DB → Return success
```

**Request (what frontend sends):**
```json
POST /auth/register
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "SecurePass123!",
  "role": "SELLER"
}
```

**Controller (handles request):**
```java
@RestController
@RequestMapping("/auth")
public class AuthController {
    
    @Autowired
    private AuthService authService;
    
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            authService.register(request);
            return ResponseEntity.ok(new MessageResponse("User registered successfully!"));
        } catch (EmailAlreadyExistsException e) {
            return ResponseEntity.badRequest().body(new ErrorResponse(e.getMessage()));
        }
    }
}
```

**Service (business logic):**
```java
@Service
public class AuthService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private BCryptPasswordEncoder passwordEncoder;
    
    @Autowired
    private KafkaTemplate kafkaTemplate;
    
    public void register(RegisterRequest request) {
        // 1. Validate email format
        if (!isValidEmail(request.getEmail())) {
            throw new InvalidEmailException("Invalid email format");
        }
        
        // 2. Check if email already exists
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyExistsException("Email already registered");
        }
        
        // 3. Validate password strength
        if (!isStrongPassword(request.getPassword())) {
            throw new WeakPasswordException("Password must be at least 8 characters with uppercase, lowercase, and numbers");
        }
        
        // 4. Create user object
        User user = new User();
        user.setName(request.getName());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));  // Hash password!
        user.setRole(request.getRole());
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        
        // 5. Save to database
        userRepository.save(user);
        
        // 6. Publish event to Kafka (notify other services)
        kafkaTemplate.send("user-registered", user.getId());
    }
}
```

**Validations Explained:**

**Email Format:**
```java
private boolean isValidEmail(String email) {
    String regex = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$";
    return email.matches(regex);
}
```

**Password Strength:**
```java
private boolean isStrongPassword(String password) {
    // At least 8 characters
    // Contains uppercase and lowercase
    // Contains numbers
    return password.length() >= 8 
        && password.matches(".*[A-Z].*")  // Has uppercase
        && password.matches(".*[a-z].*")  // Has lowercase
        && password.matches(".*\\d.*");    // Has digit
}
```

**Response:**
```json
{
  "message": "User registered successfully!"
}
```

### POST /auth/login - Login Endpoint

**Purpose:** Authenticate user and issue JWT token.

**Flow:**
```
User enters credentials → Backend verifies → Generate JWT → Return token
```

**Request:**
```json
POST /auth/login
{
  "email": "jane@example.com",
  "password": "SecurePass123!"
}
```

**Controller:**
```java
@PostMapping("/login")
public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
    try {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    } catch (InvalidCredentialsException e) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(new ErrorResponse("Invalid email or password"));
    }
}
```

**Service:**
```java
public AuthResponse login(LoginRequest request) {
    // 1. Find user by email
    User user = userRepository.findByEmail(request.getEmail())
        .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password"));
    
    // 2. Verify password
    if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
        throw new InvalidCredentialsException("Invalid email or password");
    }
    
    // 3. Generate JWT token
    String token = jwtUtil.generateToken(user);
    
    // 4. Create response (NEVER include password!)
    UserDTO userDTO = new UserDTO(user.getId(), user.getName(), user.getEmail(), user.getRole(), user.getAvatar());
    
    return new AuthResponse(token, userDTO);
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "name": "Jane Doe",
    "email": "jane@example.com",
    "role": "SELLER",
    "avatar": "https://example.com/avatar.jpg"
  }
}
```

**Security Note:** Never respond with "Email not found" or "Wrong password" separately. This reveals which emails are registered (security risk). Always use generic "Invalid credentials" message.

---

## Step 9: Profile Management APIs

### GET /api/users/me - Get Current User Profile

**Purpose:** Return logged-in user's information.

**How to know who's logged in?**
- User sends JWT token in request header
- We extract userId from token
- Fetch user from database

**Request:**
```
GET /api/users/me
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Controller:**
```java
@GetMapping("/me")
public ResponseEntity<UserDTO> getCurrentUser(@AuthenticationPrincipal User user) {
    // @AuthenticationPrincipal automatically injects logged-in user
    UserDTO userDTO = new UserDTO(user);
    return ResponseEntity.ok(userDTO);
}
```

**@AuthenticationPrincipal Explained:**
- Spring Security annotation
- Automatically extracts user from JWT token
- Provides the User object directly to your method
- No manual parsing needed!

**Response:**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "name": "Jane Doe",
  "email": "jane@example.com",
  "role": "SELLER",
  "avatar": "https://example.com/avatar.jpg",
  "createdAt": "2026-03-05T10:30:00Z"
}
```

### PUT /api/users/me - Update Profile

**Purpose:** Update logged-in user's profile information.

**Request:**
```json
PUT /api/users/me
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Body:
{
  "name": "Jane Smith",
  "email": "jane.smith@example.com",
  "avatar": "https://example.com/new-avatar.jpg"
}
```

**Controller:**
```java
@PutMapping("/me")
public ResponseEntity<UserDTO> updateProfile(
    @AuthenticationPrincipal User currentUser,
    @Valid @RequestBody UpdateProfileRequest request) {
    
    UserDTO updated = userService.updateProfile(currentUser.getId(), request);
    return ResponseEntity.ok(updated);
}
```

**Service:**
```java
public UserDTO updateProfile(String userId, UpdateProfileRequest request) {
    // 1. Find user
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new UserNotFoundException("User not found"));
    
    // 2. Update fields
    if (request.getName() != null) {
        user.setName(request.getName());
    }
    
    if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
        // Check if new email is already taken
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new EmailAlreadyExistsException("Email already in use");
        }
        user.setEmail(request.getEmail());
    }
    
    if (request.getAvatar() != null) {
        user.setAvatar(request.getAvatar());
    }
    
    user.setUpdatedAt(LocalDateTime.now());
    
    // 3. Save
    User saved = userRepository.save(user);
    
    // 4. Return DTO
    return new UserDTO(saved);
}
```

**Ownership Validation:**
- User can only update their own profile
- We get userId from JWT token (can't be faked)
- We update only that user's data
- Even if someone tries to change the userId in request, it won't work because we use the ID from the token

---

## Step 10: User Service Tests

### Why Test?
**Simple explanation:** Like checking your work:
- Make sure everything works correctly
- Catch bugs before users do
- Ensure changes don't break existing features
- Document how code should behave

### Types of Tests

**1. Unit Tests**: Test individual methods in isolation
**2. Integration Tests**: Test multiple components working together
**3. End-to-End Tests**: Test entire user flows

### Unit Test Example

**Testing UserService.register():**

```java
@ExtendWith(MockitoExtension.class)  // Use Mockito for mocking
class UserServiceTest {
    
    @Mock
    private UserRepository userRepository;  // Fake repository
    
    @Mock
    private BCryptPasswordEncoder passwordEncoder;  // Fake encoder
    
    @Mock
    private KafkaTemplate kafkaTemplate;  // Fake Kafka
    
    @InjectMocks
    private UserService userService;  // Real service with mocked dependencies
    
    @Test
    void register_ValidInput_Success() {
        // Arrange (setup)
        RegisterRequest request = new RegisterRequest();
        request.setName("John Doe");
        request.setEmail("john@example.com");
        request.setPassword("SecurePass123");
        request.setRole(Role.CLIENT);
        
        when(userRepository.existsByEmail("john@example.com")).thenReturn(false);
        when(passwordEncoder.encode("SecurePass123")).thenReturn("$2a$10$hashedpassword");
        
        // Act (execute)
        userService.register(request);
        
        // Assert (verify)
        verify(userRepository).save(any(User.class));  // Verify save was called
        verify(kafkaTemplate).send(eq("user-registered"), anyString());  // Verify Kafka event sent
    }
    
    @Test
    void register_DuplicateEmail_ThrowsException() {
        // Arrange
        RegisterRequest request = new RegisterRequest();
        request.setEmail("existing@example.com");
        
        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);
        
        // Act & Assert
        assertThrows(EmailAlreadyExistsException.class, () -> {
            userService.register(request);
        });
    }
}
```

**Mocking Explained:**
- **Mock**: Create fake version of dependencies
- **Why?** We're testing UserService, not the actual database
- Tests run fast (no real database calls)
- Tests are isolated (other components can't cause failures)

### Integration Test Example

**Testing /auth/login endpoint:**

```java
@SpringBootTest
@AutoConfigureMockMvc
class AuthControllerIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;  // Simulates HTTP requests
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private BCryptPasswordEncoder passwordEncoder;
    
    @BeforeEach
    void setup() {
        // Create test user
        User user = new User();
        user.setEmail("test@example.com");
        user.setPassword(passwordEncoder.encode("password123"));
        user.setRole(Role.CLIENT);
        userRepository.save(user);
    }
    
    @Test
    void login_ValidCredentials_ReturnsToken() throws Exception {
        // Prepare request
        String requestBody = "{\"email\":\"test@example.com\",\"password\":\"password123\"}";
        
        // Execute request
        mockMvc.perform(post("/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isOk())  // Expect 200 OK
                .andExpect(jsonPath("$.token").exists())  // Token should exist
                .andExpect(jsonPath("$.user.email").value("test@example.com"));
    }
    
    @Test
    void login_InvalidPassword_ReturnsUnauthorized() throws Exception {
        String requestBody = "{\"email\":\"test@example.com\",\"password\":\"wrongpassword\"}";
        
        mockMvc.perform(post("/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestBody))
                .andExpect(status().isUnauthorized());  // Expect 401
    }
}
```

### Test Coverage
**What it is:** Percentage of code covered by tests.

**Goal:** >80% coverage for User Service

**How to check:**
```bash
mvn test jacoco:report
```

Opens report showing which lines are tested (green) and which aren't (red).

---

## Key Takeaways

### User Service Responsibilities
1. ✅ User registration with role selection
2. ✅ Secure authentication with JWT
3. ✅ Profile management
4. ✅ Password hashing with BCrypt
5. ✅ Publishing events to Kafka

### Security Best Practices
1. 🔒 Never store plain text passwords
2. 🔒 Use BCrypt with cost factor 10-12
3. 🔒 Never return passwords in API responses
4. 🔒 Validate all inputs
5. 🔒 Use JWT for stateless authentication
6. 🔒 Set token expiration (24 hours recommended)

### Common Mistakes to Avoid
❌ Storing passwords without hashing
❌ Revealing whether email exists (security risk)
❌ Not validating input (email format, password strength)
❌ Forgetting to update `updatedAt` timestamp
❌ Including password in DTOs/responses

### Testing Checklist
- [ ] Registration with valid data works
- [ ] Registration with duplicate email fails
- [ ] Registration with weak password fails
- [ ] Login with correct credentials works
- [ ] Login with wrong password fails
- [ ] JWT token is generated correctly
- [ ] JWT token validates correctly
- [ ] Profile update works
- [ ] Can't update another user's profile

---

## Next Steps

After completing Phase 2, you should have:
✅ Working User Service with registration and login
✅ JWT-based authentication
✅ Secure password storage
✅ Profile management
✅ Comprehensive tests

**Move to Phase 3:** Media Service (file uploads and storage)
