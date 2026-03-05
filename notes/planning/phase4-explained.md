# Phase 4 Explained - Backend Development: Product Service

This document explains all concepts from Phase 4 (Product Service development) in beginner-friendly language.

---

## Overview: What is the Product Service?

**Simple explanation:** The Product Service is the core of your e-commerce platform. It handles:
- Creating new products (sellers only)
- Listing all products (everyone)
- Updating product details (sellers, their own products)
- Deleting products (sellers, their own products)
- Linking images to products
- Managing product inventory

Think of it as the "product catalog" of your store.

---

## Step 16: Product Entity & Repository

### Product Entity

**Purpose:** Represent a product in your e-commerce platform.

```java
@Document(collection = "products")
public class Product {
    @Id
    private String id;                         // Unique identifier
    
    private String name;                       // Product name
    private String description;                // Product description
    private Double price;                      // Price in dollars
    private Integer quantity;                  // Stock quantity
    private String userId;                     // Seller who created it
    private List<String> imageUrls;           // URLs of product images
    
    private LocalDateTime createdAt;           // When created
    private LocalDateTime updatedAt;           // Last update
    
    // Getters and setters...
}
```

### Fields Explained

**name**: Product name
- Example: "Gaming Laptop 15-inch"
- Required field
- Max 100 characters
- Searchable in future

**description**: Detailed information
- Example: "High-performance gaming laptop with RTX 3060..."
- Optional (can be empty)
- Max 500 characters
- Supports rich text in future

**price**: Product price
- Type: Double (allows decimals)
- Example: 1299.99
- Must be > 0
- Represents price in USD (or your currency)

**quantity**: Stock available
- Type: Integer (whole numbers)
- Example: 5 (five units in stock)
- Can be 0 (out of stock)
- Decreases when sold (in future version)

**userId**: Who owns this product
- String ID of the seller who created it
- Used for ownership validation
- Only this seller can modify/delete

**imageUrls**: List of image URLs
- Example: `["/api/media/images/abc123", "/api/media/images/def456"]`
- Array of strings
- Can be empty initially
- First URL is usually the primary image

### Product Repository

```java
public interface ProductRepository extends MongoRepository<Product, String> {
    // Find all products by a specific seller
    List<Product> findByUserId(String userId);
    
    // Find products by name (case-insensitive, partial match)
    List<Product> findByNameContainingIgnoreCase(String name);
    
    // Find products with pagination
    Page<Product> findAll(Pageable pageable);
    
    // Find products by price range
    List<Product> findByPriceBetween(Double minPrice, Double maxPrice);
    
    // Check if product exists and belongs to user
    boolean existsByIdAndUserId(String id, String userId);
}
```

**Spring Data Query Methods Explained:**

**findByUserId**: 
- Spring sees "findBy" + "UserId"
- Generates: `SELECT * FROM products WHERE userId = ?`
- Returns: List of all products by that seller

**findByNameContainingIgnoreCase**:
- "Containing" = partial match (LIKE in SQL)
- "IgnoreCase" = case-insensitive
- Example: searching "laptop" matches "Gaming Laptop" and "LAPTOP"

**findByPriceBetween**:
- Finds products in price range
- Example: findByPriceBetween(100.0, 500.0) → products between $100-$500

---

## Step 17: Product CRUD APIs - Public Endpoints

### GET /api/products - List All Products

**Purpose:** Show all available products (accessible to everyone, no login required).

**Request:**
```
GET /api/products?page=0&size=20
```

**Controller:**
```java
@RestController
@RequestMapping("/api/products")
public class ProductController {
    
    @Autowired
    private ProductService productService;
    
    @GetMapping
    public ResponseEntity<Page<ProductResponse>> getAllProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Page<ProductResponse> products = productService.getAllProducts(page, size);
        return ResponseEntity.ok(products);
    }
}
```

**No @PreAuthorize:** This endpoint is public! Anyone can view products.

**Service:**
```java
public Page<ProductResponse> getAllProducts(int page, int size) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
    Page<Product> productPage = productRepository.findAll(pageable);
    
    // Convert to DTOs
    return productPage.map(product -> new ProductResponse(
        product.getId(),
        product.getName(),
        product.getDescription(),
        product.getPrice(),
        product.getQuantity(),
        product.getImageUrls(),
        product.getCreatedAt()
    ));
}
```

**Response:**
```json
{
  "content": [
    {
      "id": "prod123",
      "name": "Gaming Laptop",
      "description": "High-performance laptop...",
      "price": 1299.99,
      "quantity": 5,
      "imageUrls": ["/api/media/images/img1", "/api/media/images/img2"],
      "createdAt": "2026-03-05T10:00:00Z"
    }
  ],
  "totalElements": 100,
  "totalPages": 5,
  "number": 0,
  "size": 20
}
```

### GET /api/products/{id} - Get Single Product

**Purpose:** View detailed information about one product.

**Request:**
```
GET /api/products/prod123
```

**Controller:**
```java
@GetMapping("/{id}")
public ResponseEntity<ProductDetailResponse> getProduct(@PathVariable String id) {
    ProductDetailResponse product = productService.getProductById(id);
    return ResponseEntity.ok(product);
}
```

**Service:**
```java
public ProductDetailResponse getProductById(String id) {
    Product product = productRepository.findById(id)
        .orElseThrow(() -> new ProductNotFoundException("Product not found with id: " + id));
    
    // Optionally fetch seller information
    User seller = userService.getUserById(product.getUserId());
    
    return new ProductDetailResponse(
        product.getId(),
        product.getName(),
        product.getDescription(),
        product.getPrice(),
        product.getQuantity(),
        product.getImageUrls(),
        new SellerInfo(seller.getName(), seller.getAvatar()),
        product.getCreatedAt()
    );
}
```

**Response:**
```json
{
  "id": "prod123",
  "name": "Gaming Laptop",
  "description": "High-performance gaming laptop with RTX 3060, 16GB RAM, 512GB SSD...",
  "price": 1299.99,
  "quantity": 5,
  "imageUrls": ["/api/media/images/img1", "/api/media/images/img2"],
  "seller": {
    "name": "Tech Store",
    "avatar": "/api/media/images/avatar123"
  },
  "createdAt": "2026-03-05T10:00:00Z"
}
```

---

## Step 18: Product CRUD APIs - Seller Endpoints

### POST /api/products - Create Product

**Purpose:** Sellers create new products.

**Request:**
```json
POST /api/products
Headers:
  Authorization: Bearer eyJhbGci...
Body:
{
  "name": "Gaming Laptop",
  "description": "High-performance laptop with RTX 3060",
  "price": 1299.99,
  "quantity": 5
}
```

**Controller:**
```java
@PostMapping
@PreAuthorize("hasRole('SELLER')")  // Only sellers
public ResponseEntity<ProductResponse> createProduct(
        @Valid @RequestBody CreateProductRequest request,
        @AuthenticationPrincipal User currentUser) {
    
    ProductResponse product = productService.createProduct(request, currentUser.getId());
    return ResponseEntity.status(HttpStatus.CREATED).body(product);
}
```

**Request DTO with Validation:**
```java
public class CreateProductRequest {
    @NotBlank(message = "Product name is required")
    @Size(max = 100, message = "Name cannot exceed 100 characters")
    private String name;
    
    @Size(max = 500, message = "Description cannot exceed 500 characters")
    private String description;
    
    @NotNull(message = "Price is required")
    @DecimalMin(value = "0.01", message = "Price must be greater than 0")
    private Double price;
    
    @NotNull(message = "Quantity is required")
    @Min(value = 0, message = "Quantity cannot be negative")
    private Integer quantity;
    
    // Getters and setters...
}
```

**Validation Annotations Explained:**

**@NotBlank**: Field cannot be null, empty, or just whitespace
- `""` → Invalid ❌
- `"   "` → Invalid ❌
- `"Laptop"` → Valid ✓

**@Size**: String length constraints
- `max = 100` → maximum 100 characters

**@NotNull**: Field must be present (but can be 0)
- `null` → Invalid ❌
- `0` → Valid ✓

**@DecimalMin**: Minimum decimal value
- `value = "0.01"` → must be at least 0.01
- `0` → Invalid ❌
- `0.01` → Valid ✓

**@Min**: Minimum integer value
- `value = 0` → must be 0 or greater
- `-1` → Invalid ❌
- `0` → Valid ✓

**Service:**
```java
public ProductResponse createProduct(CreateProductRequest request, String userId) {
    // Create product
    Product product = new Product();
    product.setName(request.getName());
    product.setDescription(request.getDescription());
    product.setPrice(request.getPrice());
    product.setQuantity(request.getQuantity());
    product.setUserId(userId);  // Set owner from JWT token
    product.setImageUrls(new ArrayList<>());  // Empty initially
    product.setCreatedAt(LocalDateTime.now());
    product.setUpdatedAt(LocalDateTime.now());
    
    // Save to database
    Product saved = productRepository.save(product);
    
    // Publish event to Kafka
    ProductCreatedEvent event = new ProductCreatedEvent(
        saved.getId(),
        saved.getName(),
        saved.getUserId()
    );
    kafkaTemplate.send("product-created", event);
    
    // Return response
    return new ProductResponse(saved);
}
```

**Response:**
```json
{
  "id": "prod123",
  "name": "Gaming Laptop",
  "description": "High-performance laptop with RTX 3060",
  "price": 1299.99,
  "quantity": 5,
  "imageUrls": [],
  "createdAt": "2026-03-05T14:30:00Z"
}
```

### PUT /api/products/{id} - Update Product

**Purpose:** Sellers update their own products.

**Request:**
```json
PUT /api/products/prod123
Headers:
  Authorization: Bearer eyJhbGci...
Body:
{
  "name": "Gaming Laptop - Updated",
  "description": "New description...",
  "price": 1199.99,
  "quantity": 3
}
```

**Controller:**
```java
@PutMapping("/{id}")
@PreAuthorize("hasRole('SELLER')")
public ResponseEntity<ProductResponse> updateProduct(
        @PathVariable String id,
        @Valid @RequestBody UpdateProductRequest request,
        @AuthenticationPrincipal User currentUser) {
    
    ProductResponse product = productService.updateProduct(id, request, currentUser.getId());
    return ResponseEntity.ok(product);
}
```

**Service with Ownership Validation:**
```java
public ProductResponse updateProduct(String productId, UpdateProductRequest request, String userId) {
    // 1. Find product
    Product product = productRepository.findById(productId)
        .orElseThrow(() -> new ProductNotFoundException("Product not found"));
    
    // 2. Verify ownership (CRITICAL!)
    if (!product.getUserId().equals(userId)) {
        throw new UnauthorizedException("You can only update your own products");
    }
    
    // 3. Update fields
    if (request.getName() != null) {
        product.setName(request.getName());
    }
    if (request.getDescription() != null) {
        product.setDescription(request.getDescription());
    }
    if (request.getPrice() != null) {
        product.setPrice(request.getPrice());
    }
    if (request.getQuantity() != null) {
        product.setQuantity(request.getQuantity());
    }
    
    product.setUpdatedAt(LocalDateTime.now());
    
    // 4. Save
    Product updated = productRepository.save(product);
    
    // 5. Publish event
    kafkaTemplate.send("product-updated", new ProductUpdatedEvent(updated.getId()));
    
    return new ProductResponse(updated);
}
```

**Ownership Validation Explained:**
```java
if (!product.getUserId().equals(userId))
```

**Why critical?**
- Without this check, any seller could modify any product!
- `userId` comes from JWT token (trustworthy)
- `product.getUserId()` comes from database (who created it)
- If they don't match → unauthorized

**Attack scenario without check:**
1. Attacker finds product ID: "prod123" (owned by another seller)
2. Attacker sends update request for "prod123"
3. Without check: ❌ Attacker successfully modifies someone else's product!
4. With check: ✅ Returns 403 Forbidden

### DELETE /api/products/{id} - Delete Product

**Purpose:** Sellers delete their own products.

**Request:**
```
DELETE /api/products/prod123
Headers:
  Authorization: Bearer eyJhbGci...
```

**Controller:**
```java
@DeleteMapping("/{id}")
@PreAuthorize("hasRole('SELLER')")
public ResponseEntity<?> deleteProduct(
        @PathVariable String id,
        @AuthenticationPrincipal User currentUser) {
    
    productService.deleteProduct(id, currentUser.getId());
    return ResponseEntity.ok(new MessageResponse("Product deleted successfully"));
}
```

**Service:**
```java
public void deleteProduct(String productId, String userId) {
    // 1. Find product
    Product product = productRepository.findById(productId)
        .orElseThrow(() -> new ProductNotFoundException("Product not found"));
    
    // 2. Verify ownership
    if (!product.getUserId().equals(userId)) {
        throw new UnauthorizedException("You can only delete your own products");
    }
    
    // 3. Optional: Delete associated images
    if (!product.getImageUrls().isEmpty()) {
        // Option A: Delete images from Media Service
        for (String imageUrl : product.getImageUrls()) {
            String mediaId = extractMediaId(imageUrl);
            mediaService.deleteImage(mediaId, userId);
        }
        
        // Option B: Just unlink (keep images in Media Service)
        // Do nothing, images remain in media library
    }
    
    // 4. Delete product
    productRepository.delete(product);
    
    // 5. Publish event
    kafkaTemplate.send("product-deleted", new ProductDeletedEvent(productId, userId));
}
```

---

## Step 19: Product-Media Integration

### POST /api/products/{id}/images - Link Images to Product

**Purpose:** Add images to product after uploading them to Media Service.

**Flow:**
```
1. Upload image to Media Service → get media ID
2. Link media ID to product
```

**Request:**
```json
POST /api/products/prod123/images
Headers:
  Authorization: Bearer eyJhbGci...
Body:
{
  "mediaIds": ["media1", "media2", "media3"]
}
```

**Controller:**
```java
@PostMapping("/{id}/images")
@PreAuthorize("hasRole('SELLER')")
public ResponseEntity<ProductResponse> addImages(
        @PathVariable String id,
        @RequestBody AddImagesRequest request,
        @AuthenticationPrincipal User currentUser) {
    
    ProductResponse product = productService.addImages(id, request.getMediaIds(), currentUser.getId());
    return ResponseEntity.ok(product);
}
```

**Service:**
```java
public ProductResponse addImages(String productId, List<String> mediaIds, String userId) {
    // 1. Find product
    Product product = productRepository.findById(productId)
        .orElseThrow(() -> new ProductNotFoundException("Product not found"));
    
    // 2. Verify ownership
    if (!product.getUserId().equals(userId)) {
        throw new UnauthorizedException("You can only modify your own products");
    }
    
    // 3. Validate media exists and belongs to user
    for (String mediaId : mediaIds) {
        Media media = mediaRepository.findById(mediaId)
            .orElseThrow(() -> new MediaNotFoundException("Media not found: " + mediaId));
        
        if (!media.getUserId().equals(userId)) {
            throw new UnauthorizedException("You can only use your own media");
        }
        
        // Build image URL
        String imageUrl = "/api/media/images/" + mediaId;
        
        // Add to product if not already present
        if (!product.getImageUrls().contains(imageUrl)) {
            product.getImageUrls().add(imageUrl);
        }
    }
    
    // 4. Save
    product.setUpdatedAt(LocalDateTime.now());
    Product updated = productRepository.save(product);
    
    return new ProductResponse(updated);
}
```

### Kafka Consumer: Auto-link Images

**Purpose:** Automatically link images when uploaded with productId.

**Scenario:**
- User uploads image and specifies productId
- Media Service publishes "image-uploaded" event
- Product Service listens and automatically adds image to product

**Consumer:**
```java
@Service
public class ImageUploadedConsumer {
    
    @Autowired
    private ProductRepository productRepository;
    
    @KafkaListener(topics = "image-uploaded", groupId = "product-service")
    public void handleImageUploaded(ImageUploadedEvent event) {
        // Only process if productId is specified
        if (event.getProductId() != null) {
            Product product = productRepository.findById(event.getProductId())
                .orElse(null);
            
            if (product != null && product.getUserId().equals(event.getUserId())) {
                String imageUrl = "/api/media/images/" + event.getMediaId();
                
                if (!product.getImageUrls().contains(imageUrl)) {
                    product.getImageUrls().add(imageUrl);
                    product.setUpdatedAt(LocalDateTime.now());
                    productRepository.save(product);
                }
            }
        }
    }
}
```

**Event class:**
```java
public class ImageUploadedEvent {
    private String mediaId;
    private String productId;  // Optional
    private String userId;
    
    // Constructors, getters, setters...
}
```

**Benefits:**
- Seamless integration between services
- User doesn't need to manually link images
- Services remain decoupled (loosely coupled via events)

---

## Step 20: Product Service Tests

### Unit Test: Create Product

```java
@ExtendWith(MockitoExtension.class)
class ProductServiceTest {
    
    @Mock
    private ProductRepository productRepository;
    
    @Mock
    private KafkaTemplate kafkaTemplate;
    
    @InjectMocks
    private ProductService productService;
    
    @Test
    void createProduct_ValidInput_Success() {
        // Arrange
        CreateProductRequest request = new CreateProductRequest();
        request.setName("Test Product");
        request.setPrice(99.99);
        request.setQuantity(10);
        
        String userId = "seller123";
        
        Product saved = new Product();
        saved.setId("prod123");
        saved.setName(request.getName());
        saved.setUserId(userId);
        
        when(productRepository.save(any(Product.class))).thenReturn(saved);
        
        // Act
        ProductResponse response = productService.createProduct(request, userId);
        
        // Assert
        assertNotNull(response);
        assertEquals("Test Product", response.getName());
        verify(productRepository).save(any(Product.class));
        verify(kafkaTemplate).send(eq("product-created"), any());
    }
}
```

### Integration Test: Update with Ownership Check

```java
@SpringBootTest
@AutoConfigureMockMvc
class ProductControllerIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Autowired
    private ProductRepository productRepository;
    
    @Autowired
    private JwtUtil jwtUtil;
    
    private String sellerToken;
    private String anotherSellerToken;
    private Product testProduct;
    
    @BeforeEach
    void setup() {
        User seller1 = new User();
        seller1.setId("seller1");
        seller1.setRole(Role.SELLER);
        sellerToken = jwtUtil.generateToken(seller1);
        
        User seller2 = new User();
        seller2.setId("seller2");
        seller2.setRole(Role.SELLER);
        anotherSellerToken = jwtUtil.generateToken(seller2);
        
        testProduct = new Product();
        testProduct.setName("Original Product");
        testProduct.setPrice(100.0);
        testProduct.setQuantity(5);
        testProduct.setUserId("seller1");
        testProduct = productRepository.save(testProduct);
    }
    
    @Test
    void updateProduct_AsOwner_Success() throws Exception {
        String updateJson = "{\"name\":\"Updated Product\",\"price\":120.0}";
        
        mockMvc.perform(put("/api/products/" + testProduct.getId())
                .header("Authorization", "Bearer " + sellerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updateJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated Product"))
                .andExpect(jsonPath("$.price").value(120.0));
    }
    
    @Test
    void updateProduct_AsNonOwner_Forbidden() throws Exception {
        String updateJson = "{\"name\":\"Hacked Product\"}";
        
        mockMvc.perform(put("/api/products/" + testProduct.getId())
                .header("Authorization", "Bearer " + anotherSellerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updateJson))
                .andExpect(status().isForbidden());  // 403
    }
}
```

---

## Key Takeaways

### Product Service Responsibilities
1. ✅ CRUD operations for products
2. ✅ Public access for viewing products
3. ✅ Seller-only access for creating/updating
4. ✅ Ownership validation for modifications
5. ✅ Integration with Media Service for images
6. ✅ Kafka event publishing

### Security Best Practices
1. 🔒 Always validate ownership before update/delete
2. 🔒 Use @PreAuthorize for role checks
3. 🔒 Extract userId from JWT (don't trust request body)
4. 🔒 Validate all inputs with @Valid annotations
5. 🔒 Return 403 for ownership violations

### Data Integrity
- Price must be positive
- Quantity cannot be negative
- Product must have a name
- Owner (userId) must be valid
- Images must belong to same user

### Common Mistakes
❌ Not checking ownership (biggest security risk!)
❌ Trusting userId from request body
❌ Allowing negative prices or quantities
❌ Not publishing Kafka events
❌ Missing validation annotations

---

## Next Steps

After completing Phase 4, you should have:
✅ Complete Product CRUD functionality
✅ Public and seller-specific endpoints
✅ Ownership-based access control
✅ Integration with Media Service
✅ Kafka event publishing
✅ Comprehensive tests

**Move to Phase 5:** API Gateway configuration and security filters
