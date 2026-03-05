# Phase 3 Explained - Backend Development: Media Service

This document explains all concepts from Phase 3 (Media Service development) in beginner-friendly language.

---

## Overview: What is the Media Service?

**Simple explanation:** The Media Service handles everything related to file uploads:
- Receiving image uploads from users
- Validating file types and sizes
- Storing images safely
- Serving images when requested
- Managing media metadata

Think of it as the "photo department" that stores and organizes all product images and user avatars.

---

## Step 11: Media Entity & Storage Configuration

### Media Entity

**Purpose:** Store metadata about uploaded files.

**Why separate metadata from actual file?**
- Files are stored on disk or cloud storage (physical files)
- Metadata is stored in database (information about files)
- This separation allows efficient querying and management

**Media Entity:**
```java
@Document(collection = "media")
public class Media {
    @Id
    private String id;                    // Unique identifier
    
    private String fileName;              // Original filename: "laptop.jpg"
    private String filePath;              // Where stored: "/uploads/abc123.jpg"
    private String productId;             // Which product (optional, nullable)
    private String userId;                // Who uploaded it
    private String contentType;           // MIME type: "image/jpeg"
    private Long size;                    // File size in bytes
    private LocalDateTime uploadedAt;     // When uploaded
    
    // Getters and setters...
}
```

### Fields Explained

**fileName**: Original name when user uploaded
- User uploads "my-product-photo.jpg"
- We store this original name for reference
- Not used for actual storage (we generate unique names)

**filePath**: Where file is actually stored
- Generated unique path: "/uploads/2026/03/abc123-uuid.jpg"
- Prevents filename conflicts
- Can include folder structure for organization

**productId**: Optional link to product
- If uploading for a product, store product ID
- Can be null if just uploading to media library
- Allows finding all images for a product

**userId**: Who uploaded (seller ID)
- For ownership validation
- Only uploader can delete
- For listing user's media

**contentType**: MIME type
- "image/jpeg" for .jpg files
- "image/png" for .png files
- "image/gif" for .gif files
- Used when serving file to browser

**size**: File size in bytes
- For validation (ensure ≤ 2MB)
- For statistics
- For quotas (if implementing storage limits)

### File Storage Configuration

**Where to store files?**

**Option 1: Local filesystem** (development/small scale)
```yaml
# application.yml
file:
  upload:
    dir: /uploads
    max-size: 2MB  # 2,097,152 bytes
```

**Pros:** Simple, no external dependencies
**Cons:** Not scalable, files lost if server crashes

**Option 2: Cloud storage** (production/large scale)
- AWS S3
- Google Cloud Storage
- Azure Blob Storage

**Pros:** Scalable, reliable, backed up
**Cons:** Costs money, more complex setup

**Configuration class:**
```java
@Configuration
public class FileStorageConfig {
    
    @Value("${file.upload.dir}")
    private String uploadDir;
    
    @Bean
    public void createUploadDirectory() {
        File directory = new File(uploadDir);
        if (!directory.exists()) {
            directory.mkdirs();  // Create directory if doesn't exist
        }
    }
}
```

### MediaRepository

```java
public interface MediaRepository extends MongoRepository<Media, String> {
    // Find all media uploaded by a user
    List<Media> findByUserId(String userId);
    
    // Find all media for a product
    List<Media> findByProductId(String productId);
    
    // Find unlinked media (not assigned to any product)
    List<Media> findByProductIdIsNull();
    
    // Check if media exists
    boolean existsByIdAndUserId(String id, String userId);
}
```

---

## Step 12: File Upload Validation

### Why Validate?

**Security risks without validation:**
- User uploads virus disguised as image
- User uploads huge file (crashes server)
- User uploads executable file (.exe)
- User tries to upload non-image files

**We must validate:**
1. File type (images only)
2. File size (max 2 MB)
3. File content (actual image, not renamed executable)

### MIME Type

**What it is:** A standard way to identify file types.

**Common MIME types:**
- `image/jpeg` - JPEG images
- `image/png` - PNG images
- `image/gif` - GIF images
- `image/webp` - WebP images
- `text/html` - HTML files
- `application/pdf` - PDF files

**MIME type format:**
```
type/subtype
```

**Checking MIME type:**
```java
public boolean isImage(MultipartFile file) {
    String contentType = file.getContentType();
    
    // Check if starts with "image/"
    return contentType != null && contentType.startsWith("image/");
}
```

**Problem:** Users can fake MIME types!
- Rename virus.exe to virus.jpg
- Manipulate MIME type header
- Operating system reports wrong type

**Solution:** Check file content (magic bytes)

### Magic Bytes

**What are they?** First few bytes of a file that identify its true type.

**Simple explanation:** Like a signature at the start of each file type.

**Examples:**
- JPEG: `FF D8 FF`
- PNG: `89 50 4E 47`
- GIF: `47 49 46 38`
- PDF: `25 50 44 46`

**Checking magic bytes:**
```java
public boolean isValidImage(MultipartFile file) {
    try {
        byte[] bytes = new byte[8];
        InputStream input = file.getInputStream();
        input.read(bytes);
        input.close();
        
        // Check for JPEG
        if (bytes[0] == (byte) 0xFF && bytes[1] == (byte) 0xD8 && bytes[2] == (byte) 0xFF) {
            return true;
        }
        
        // Check for PNG
        if (bytes[0] == (byte) 0x89 && bytes[1] == (byte) 0x50 && 
            bytes[2] == (byte) 0x4E && bytes[3] == (byte) 0x47) {
            return true;
        }
        
        // Check for GIF
        if (bytes[0] == (byte) 0x47 && bytes[1] == (byte) 0x49 && bytes[2] == (byte) 0x46) {
            return true;
        }
        
        return false;
    } catch (IOException e) {
        return false;
    }
}
```

### File Validator Component

**Complete validator:**
```java
@Component
public class FileValidator {
    
    private static final long MAX_FILE_SIZE = 2 * 1024 * 1024;  // 2 MB in bytes
    private static final List<String> ALLOWED_CONTENT_TYPES = Arrays.asList(
        "image/jpeg", "image/png", "image/gif", "image/webp"
    );
    
    public void validate(MultipartFile file) {
        // Check if file is empty
        if (file.isEmpty()) {
            throw new InvalidFileException("File is empty");
        }
        
        // Check file size
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new FileSizeExceededException(
                "File size exceeds maximum allowed size of 2MB"
            );
        }
        
        // Check MIME type
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new InvalidFileTypeException(
                "Only image files (JPEG, PNG, GIF, WebP) are allowed"
            );
        }
        
        // Check magic bytes (file content)
        if (!isValidImageContent(file)) {
            throw new InvalidFileException(
                "File content does not match image format"
            );
        }
    }
    
    private boolean isValidImageContent(MultipartFile file) {
        // Implementation from above...
    }
}
```

### Filename Sanitization

**Why needed?** Prevent security vulnerabilities from malicious filenames.

**Dangerous filenames:**
- `../../etc/passwd` (path traversal)
- `image; rm -rf /` (command injection)
- `<script>alert('xss')</script>.jpg` (XSS)

**Sanitization:**
```java
public String sanitizeFilename(String originalFilename) {
    if (originalFilename == null) {
        return "unnamed";
    }
    
    // Remove path information
    String filename = Paths.get(originalFilename).getFileName().toString();
    
    // Remove or replace dangerous characters
    filename = filename.replaceAll("[^a-zA-Z0-9.-]", "_");
    
    // Ensure filename isn't too long
    if (filename.length() > 100) {
        filename = filename.substring(0, 100);
    }
    
    return filename;
}
```

### Unique Filename Generation

**Why?** Prevent overwriting files with same name.

**Without unique names:**
- User A uploads "product.jpg"
- User B uploads "product.jpg"
- User A's file is overwritten!

**With unique names:**
```java
public String generateUniqueFilename(String originalFilename) {
    // Extract extension
    String extension = "";
    int dotIndex = originalFilename.lastIndexOf('.');
    if (dotIndex > 0) {
        extension = originalFilename.substring(dotIndex);  // ".jpg"
    }
    
    // Generate UUID (universally unique identifier)
    String uuid = UUID.randomUUID().toString();  // "a3bb189e-8bf9-3888-9912-ace4e6543002"
    
    // Combine: uuid + extension
    return uuid + extension;  // "a3bb189e-8bf9-3888-9912-ace4e6543002.jpg"
}
```

**Alternative: Include timestamp and user ID:**
```java
public String generateUniqueFilename(String originalFilename, String userId) {
    String extension = getExtension(originalFilename);
    String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
    String uuid = UUID.randomUUID().toString().substring(0, 8);
    
    // Result: "20260305-143022_userId123_a3bb189e.jpg"
    return timestamp + "_" + userId + "_" + uuid + extension;
}
```

---

## Step 13: Media Upload API

### POST /api/media/images - Upload Endpoint

**Purpose:** Accept image upload from authenticated sellers.

**Request (multipart/form-data):**
```
POST /api/media/images
Headers:
  Authorization: Bearer eyJhbGci...
  Content-Type: multipart/form-data

Form Data:
  file: [actual image file]
  productId: "507f1f77bcf86cd799439011" (optional)
```

**Controller:**
```java
@RestController
@RequestMapping("/api/media")
public class MediaController {
    
    @Autowired
    private MediaService mediaService;
    
    @PostMapping("/images")
    @PreAuthorize("hasRole('SELLER')")  // Only sellers can upload
    public ResponseEntity<MediaResponse> uploadImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "productId", required = false) String productId,
            @AuthenticationPrincipal User currentUser) {
        
        MediaResponse response = mediaService.uploadImage(file, productId, currentUser.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
```

**@PreAuthorize Explained:**
- Spring Security annotation
- Checks user's role before allowing method execution
- `hasRole('SELLER')` = only users with SELLER role can access
- Returns 403 Forbidden if role doesn't match

**MultipartFile:**
- Spring's representation of uploaded file
- Provides methods:
  - `getOriginalFilename()` - original name
  - `getSize()` - file size
  - `getContentType()` - MIME type
  - `getBytes()` - file content as byte array
  - `transferTo(File)` - save to disk

**Service Implementation:**
```java
@Service
public class MediaService {
    
    @Autowired
    private FileValidator fileValidator;
    
    @Autowired
    private MediaRepository mediaRepository;
    
    @Autowired
    private KafkaTemplate kafkaTemplate;
    
    @Value("${file.upload.dir}")
    private String uploadDir;
    
    public MediaResponse uploadImage(MultipartFile file, String productId, String userId) {
        // 1. Validate file
        fileValidator.validate(file);
        
        // 2. Generate unique filename
        String originalFilename = file.getOriginalFilename();
        String sanitized = sanitizeFilename(originalFilename);
        String uniqueFilename = generateUniqueFilename(sanitized);
        
        // 3. Create directory structure (year/month)
        String dateFolder = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy/MM"));
        String fullPath = uploadDir + "/" + dateFolder;
        File directory = new File(fullPath);
        if (!directory.exists()) {
            directory.mkdirs();
        }
        
        // 4. Save file to disk
        String filePath = fullPath + "/" + uniqueFilename;
        try {
            file.transferTo(new File(filePath));
        } catch (IOException e) {
            throw new FileStorageException("Failed to store file", e);
        }
        
        // 5. Save metadata to database
        Media media = new Media();
        media.setFileName(originalFilename);
        media.setFilePath(filePath);
        media.setProductId(productId);
        media.setUserId(userId);
        media.setContentType(file.getContentType());
        media.setSize(file.getSize());
        media.setUploadedAt(LocalDateTime.now());
        
        Media saved = mediaRepository.save(media);
        
        // 6. Publish event to Kafka
        ImageUploadedEvent event = new ImageUploadedEvent(saved.getId(), productId, userId);
        kafkaTemplate.send("image-uploaded", event);
        
        // 7. Return response
        String url = "/api/media/images/" + saved.getId();
        return new MediaResponse(saved.getId(), originalFilename, url, file.getSize());
    }
}
```

**Flow visualization:**
```
1. Receive file → 2. Validate → 3. Generate unique name → 
4. Save to disk → 5. Save metadata to DB → 6. Publish event → 7. Return response
```

**Response:**
```json
{
  "id": "65f1e2b3c4a5d6e7f8a9b0c1",
  "fileName": "laptop-photo.jpg",
  "url": "/api/media/images/65f1e2b3c4a5d6e7f8a9b0c1",
  "size": 1048576
}
```

---

## Step 14: Media Retrieval & Management APIs

### GET /api/media/images/{id} - Serve Image

**Purpose:** Retrieve and serve the actual image file.

**Controller:**
```java
@GetMapping("/images/{id}")
public ResponseEntity<Resource> getImage(@PathVariable String id) {
    return mediaService.getImage(id);
}
```

**Service:**
```java
public ResponseEntity<Resource> getImage(String id) {
    // 1. Find media metadata
    Media media = mediaRepository.findById(id)
        .orElseThrow(() -> new MediaNotFoundException("Media not found"));
    
    // 2. Load file from disk
    try {
        Path filePath = Paths.get(media.getFilePath());
        Resource resource = new UrlResource(filePath.toUri());
        
        if (!resource.exists() || !resource.isReadable()) {
            throw new MediaNotFoundException("File not found or not readable");
        }
        
        // 3. Return file with appropriate headers
        return ResponseEntity.ok()
            .contentType(MediaType.parseMediaType(media.getContentType()))
            .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + media.getFileName() + "\"")
            .header(HttpHeaders.CACHE_CONTROL, "max-age=31536000")  // Cache for 1 year
            .header(HttpHeaders.ETAG, media.getId())  // For conditional requests
            .body(resource);
            
    } catch (MalformedURLException e) {
        throw new FileStorageException("Error loading file", e);
    }
}
```

**Headers Explained:**

**Content-Type:** Tells browser what type of file this is
- Browser uses this to render correctly
- `image/jpeg` → browser displays as image
- `application/pdf` → browser opens PDF viewer

**Content-Disposition:** How browser should handle file
- `inline` → display in browser
- `attachment` → download file
- `filename="..."` → suggested filename for download

**Cache-Control:** How long browser should cache file
- `max-age=31536000` → cache for 1 year (images don't change)
- Improves performance (browser doesn't re-download)
- Use shorter time for frequently changing content

**ETag:** Unique identifier for this version of the resource
- Browser can ask: "I have version X, has it changed?"
- Server responds: "No change" (304 Not Modified) or sends new file
- Saves bandwidth

### GET /api/media/images - List User's Media

**Purpose:** Get all images uploaded by current user.

**Request:**
```
GET /api/media/images?page=0&size=20
Headers:
  Authorization: Bearer eyJhbGci...
```

**Controller:**
```java
@GetMapping("/images")
@PreAuthorize("hasRole('SELLER')")
public ResponseEntity<Page<MediaResponse>> getUserMedia(
        @AuthenticationPrincipal User currentUser,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size) {
    
    Page<MediaResponse> media = mediaService.getUserMedia(currentUser.getId(), page, size);
    return ResponseEntity.ok(media);
}
```

**Service with Pagination:**
```java
public Page<MediaResponse> getUserMedia(String userId, int page, int size) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("uploadedAt").descending());
    Page<Media> mediaPage = mediaRepository.findByUserId(userId, pageable);
    
    // Convert to response DTOs
    return mediaPage.map(media -> new MediaResponse(
        media.getId(),
        media.getFileName(),
        "/api/media/images/" + media.getId(),
        media.getSize(),
        media.getUploadedAt()
    ));
}
```

**Pagination Explained:**
- Don't return all images at once (could be thousands!)
- Return small chunks (pages)
- `page=0, size=20` → first 20 items
- `page=1, size=20` → items 21-40
- Includes total count in response

**Response:**
```json
{
  "content": [
    {
      "id": "65f1e2b3c4a5d6e7f8a9b0c1",
      "fileName": "product1.jpg",
      "url": "/api/media/images/65f1e2b3c4a5d6e7f8a9b0c1",
      "size": 1048576,
      "uploadedAt": "2026-03-05T14:30:00Z"
    }
  ],
  "totalElements": 45,
  "totalPages": 3,
  "size": 20,
  "number": 0
}
```

### DELETE /api/media/images/{id} - Delete Image

**Purpose:** Delete image file and metadata.

**Controller:**
```java
@DeleteMapping("/images/{id}")
@PreAuthorize("hasRole('SELLER')")
public ResponseEntity<?> deleteImage(
        @PathVariable String id,
        @AuthenticationPrincipal User currentUser) {
    
    mediaService.deleteImage(id, currentUser.getId());
    return ResponseEntity.ok(new MessageResponse("Image deleted successfully"));
}
```

**Service:**
```java
public void deleteImage(String mediaId, String userId) {
    // 1. Find media
    Media media = mediaRepository.findById(mediaId)
        .orElseThrow(() -> new MediaNotFoundException("Media not found"));
    
    // 2. Verify ownership
    if (!media.getUserId().equals(userId)) {
        throw new UnauthorizedException("You don't have permission to delete this media");
    }
    
    // 3. Check if media is used by a product
    if (media.getProductId() != null) {
        // Optional: prevent deletion if linked to product
        // Or: remove from product's imageUrls first
        throw new MediaInUseException("Cannot delete media linked to a product");
    }
    
    // 4. Delete file from disk
    try {
        Path filePath = Paths.get(media.getFilePath());
        Files.deleteIfExists(filePath);
    } catch (IOException e) {
        // Log error but continue (metadata still removed)
        logger.error("Failed to delete physical file: " + media.getFilePath(), e);
    }
    
    // 5. Delete metadata from database
    mediaRepository.delete(media);
}
```

**Ownership Check:**
```
if (!media.getUserId().equals(userId))
```
- Critical security check!
- Users can only delete their own images
- Even if someone knows the media ID, they can't delete others' images

---

## Step 15: Media Service Tests

### Unit Test: File Validator

```java
@Test
void validate_ValidImage_NoException() {
    MockMultipartFile file = new MockMultipartFile(
        "file",
        "test.jpg",
        "image/jpeg",
        "fake image content".getBytes()
    );
    
    // Should not throw exception
    assertDoesNotThrow(() -> fileValidator.validate(file));
}

@Test
void validate_FileTooLarge_ThrowsException() {
    byte[] largeContent = new byte[3 * 1024 * 1024];  // 3 MB
    MockMultipartFile file = new MockMultipartFile(
        "file",
        "large.jpg",
        "image/jpeg",
        largeContent
    );
    
    assertThrows(FileSizeExceededException.class, () -> {
        fileValidator.validate(file);
    });
}

@Test
void validate_InvalidMimeType_ThrowsException() {
    MockMultipartFile file = new MockMultipartFile(
        "file",
        "document.pdf",
        "application/pdf",
        "pdf content".getBytes()
    );
    
    assertThrows(InvalidFileTypeException.class, () -> {
        fileValidator.validate(file);
    });
}
```

### Integration Test: Upload Endpoint

```java
@SpringBootTest
@AutoConfigureMockMvc
class MediaControllerIntegrationTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Autowired
    private JwtUtil jwtUtil;
    
    private String sellerToken;
    
    @BeforeEach
    void setup() {
        User seller = new User();
        seller.setId("seller123");
        seller.setRole(Role.SELLER);
        sellerToken = jwtUtil.generateToken(seller);
    }
    
    @Test
    void uploadImage_ValidImage_Success() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "product.jpg",
            "image/jpeg",
            "fake image content".getBytes()
        );
        
        mockMvc.perform(multipart("/api/media/images")
                .file(file)
                .header("Authorization", "Bearer " + sellerToken))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").exists())
                .andExpect(jsonPath("$.fileName").value("product.jpg"))
                .andExpect(jsonPath("$.url").exists());
    }
    
    @Test
    void uploadImage_AsClient_Forbidden() throws Exception {
        User client = new User();
        client.setRole(Role.CLIENT);
        String clientToken = jwtUtil.generateToken(client);
        
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "product.jpg",
            "image/jpeg",
            "content".getBytes()
        );
        
        mockMvc.perform(multipart("/api/media/images")
                .file(file)
                .header("Authorization", "Bearer " + clientToken))
                .andExpect(status().isForbidden());  // 403
    }
}
```

---

## Key Takeaways

### Media Service Responsibilities
1. ✅ Accept image uploads from sellers
2. ✅ Validate file type, size, and content
3. ✅ Store files securely with unique names
4. ✅ Serve images with appropriate headers
5. ✅ Manage media metadata
6. ✅ Enforce ownership for deletions

### Security Best Practices
1. 🔒 Validate MIME type AND magic bytes
2. 🔒 Enforce file size limits (2 MB)
3. 🔒 Generate unique filenames (prevent overwrites)
4. 🔒 Sanitize filenames (prevent path traversal)
5. 🔒 Check ownership before deletion
6. 🔒 Only allow SELLER role to upload

### Common Pitfalls
❌ Trusting MIME type from client (can be faked)
❌ Using original filename (security risk)
❌ Not checking file size (DoS attack)
❌ Missing ownership validation (anyone could delete)
❌ Storing files without organization (hard to manage)

### Performance Tips
💡 Use caching headers for images
💡 Organize files in date-based folders
💡 Consider CDN for production (faster delivery)
💡 Implement pagination for media lists
💡 Add image compression/resizing (save space)

---

## Next Steps

After completing Phase 3, you should have:
✅ Working Media Service with upload/download
✅ Comprehensive file validation
✅ Secure file storage
✅ Ownership-based access control
✅ Kafka event publishing

**Move to Phase 4:** Product Service (CRUD operations and integration with Media Service)
