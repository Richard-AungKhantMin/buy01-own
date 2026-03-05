# Phase 1 Explained - For Programming Beginners

This document explains all the technical terms and concepts from Phase 1 in simple, beginner-friendly language.

---

## Step 1: Initialize Project Structure

### What is a Project Structure?
Think of building a house. Before you start, you need a blueprint showing where each room goes, how they connect, and what purpose each serves. In software, a project structure is like that blueprint - it organizes your code files into folders so everything is easy to find and maintain.

### Maven / Gradle
**What they are:** Build tools - like automated assistants that help you manage your project.

**Simple explanation:** Imagine you're baking a cake. You need:
- A recipe (your code)
- Ingredients (external libraries and tools)
- Instructions on mixing everything together
- An oven to bake it (compilation)

Maven and Gradle are like recipe managers that:
- Download all the ingredients (libraries) you need automatically
- Mix everything in the right order
- Compile your code into a working application
- Run tests to make sure everything works

**Example:** If you need a library to connect to a database, instead of downloading it manually, you just write one line in your Maven/Gradle file, and it gets it for you.

**Choose one:** You only need either Maven OR Gradle, not both. Maven is older and more common; Gradle is newer and faster.

### Spring Boot
**What it is:** A framework (pre-built toolkit) for building web applications in Java.

**Simple explanation:** Imagine you're building a car. You could:
- Design every single part from scratch (nuts, bolts, engine, wheels) - very hard!
- OR use a car kit with pre-built parts that fit together - much easier!

Spring Boot is like that car kit. It provides:
- Pre-built components for common tasks (handling web requests, security, database connections)
- Smart defaults so you don't have to configure everything
- A way to quickly create professional applications

**Why Spring Boot for microservices?** It's specifically designed to make it easy to create small, independent services that work together.

### Microservices
**What they are:** A way of building applications as a collection of small, independent services instead of one big program.

**Simple explanation:** 

**Old way (Monolithic):** Imagine a restaurant where one person does EVERYTHING - takes orders, cooks food, cleans dishes, handles payments. If that person is sick, the whole restaurant stops.

**Microservices way:** Different people handle different jobs:
- Waiter takes orders (User Service)
- Chef cooks food (Product Service)
- Cashier handles payments (Media Service)
- Manager coordinates everything (API Gateway)

If the cashier is sick, you can still take orders and cook food. Each service is independent but works together.

**In this project, we have:**
- **user-service**: Handles user registration, login, profiles
- **product-service**: Manages products (create, read, update, delete)
- **media-service**: Handles image uploads and storage
- **api-gateway**: The front door that routes requests to the right service
- **discovery-service**: A phone book that helps services find each other

### Angular
**What it is:** A framework for building modern web applications (the part users see and interact with).

**Simple explanation:** Angular helps you build the "user interface" - the buttons, forms, and pages users click on in their browser.

Think of a restaurant again:
- **Backend (Spring Boot services)**: The kitchen where food is prepared
- **Frontend (Angular)**: The dining room where customers sit and order

Angular provides:
- Components (reusable pieces of UI like buttons, forms, cards)
- Routing (navigation between different pages)
- Tools to connect to your backend services
- Automatic updates when data changes

### Workspace
**What it is:** The folder on your computer where all your project code lives.

**Simple explanation:** Think of it as your project's home directory. Everything related to your project - code files, configuration, documentation - lives inside this folder.

**Example structure:**
```
buy01-own/                    (Main workspace folder)
├── backend/                   (All backend services)
│   ├── user-service/         (User management code)
│   ├── product-service/      (Product management code)
│   ├── media-service/        (Image upload code)
│   ├── api-gateway/          (Gateway code)
│   └── discovery-service/    (Service discovery code)
└── frontend/                  (Angular application)
    └── ecommerce-app/
```

### .gitignore
**What it is:** A file that tells Git which files to ignore (not track).

**Simple explanation:** Imagine taking photos of your workspace but wanting to exclude personal items. `.gitignore` is like a list saying "don't photograph these things."

**Common things to ignore:**
- Compiled code (you can rebuild it)
- Downloaded libraries (you can re-download them)
- Personal settings or passwords
- Temporary files

**Example .gitignore content:**
```
target/           # Compiled Java files
node_modules/     # Downloaded JavaScript libraries
*.log            # Log files
.env             # Environment variables with secrets
```

### Version Control (Git)
**What it is:** A system that tracks changes to your code over time, like a time machine for your project.

**Simple explanation:** Imagine writing a novel:
- **Without version control:** You make changes and save. If you mess up, you can't go back. If you want to try different endings, you need multiple file copies (novel_v1.doc, novel_v2.doc, novel_final_FINAL.doc).
- **With version control (Git):** Every time you make changes, you create a "save point" (called a commit). You can:
  - Go back to any previous version
  - See exactly what changed and when
  - Try experimental changes in separate "branches"
  - Work with teammates without overwriting each other's work

**Key Git concepts:**
- **Repository (repo):** Your project folder that Git is tracking
- **Commit:** A snapshot of your code at a point in time (like a save point)
- **Branch:** A separate line of development (like parallel universes of your code)
- **Remote:** A copy of your repository on the internet (like GitHub)

**Basic workflow:**
```bash
git init              # Start tracking a project
git add .             # Stage your changes
git commit -m "..."   # Save a snapshot with a message
git push              # Upload to GitHub/GitLab
```

---

## Step 2: Configure Service Discovery

### Service Discovery
**What it is:** A way for microservices to find and communicate with each other automatically.

**Simple explanation:** Imagine a large office building with many departments:

**Without service discovery:** To send a document to Accounting, you need to memorize their room number (like "3rd floor, room 305"). If they move to a different room, everyone needs to update their records.

**With service discovery (Eureka):** There's a reception desk that knows where every department is. You just ask for "Accounting," and the receptionist tells you where to go. If departments move, only the receptionist needs to know.

**Benefits:**
- Services don't need to know each other's exact addresses
- New services can join automatically
- If a service crashes and restarts, others can still find it

### Eureka Discovery Server
**What it is:** Netflix's service discovery solution that acts as a "phone book" for microservices.

**How it works:**
1. **Registration:** When a service starts, it registers itself with Eureka:
   - "Hi, I'm user-service, and I'm running at localhost:8081"
2. **Discovery:** When another service needs to talk to user-service:
   - Asks Eureka: "Where is user-service?"
   - Eureka responds: "It's at localhost:8081"
3. **Health checks:** Eureka regularly checks if services are still alive

**Real-world analogy:** Like a phone book that automatically updates when people move or get new phone numbers.

### Dependencies
**What they are:** External code libraries that your project needs to work.

**Simple explanation:** Think of building with LEGO:
- You could craft your own plastic bricks (writing everything from scratch) - very hard!
- Or you buy LEGO sets (use dependencies) - much easier!

A dependency is pre-written code that someone else created, which you can use in your project.

**Example:** Instead of writing code to connect to a database from scratch (hundreds of lines), you add a "database dependency" (one line), and it's done for you.

**In Maven (pom.xml):**
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>
```

This downloads and includes the Eureka server code in your project.

### Port
**What it is:** A number that identifies a specific application on a computer.

**Simple explanation:** Imagine an apartment building (your computer):
- The building has one address (IP address like 192.168.1.1)
- Each apartment has a number (port like 8080, 8761)
- Different services live in different apartments

**Common ports:**
- Port 8761: Eureka Discovery Server
- Port 8080: API Gateway
- Port 8081: User Service
- Port 8082: Product Service
- Port 8083: Media Service

**Why different ports?** So multiple services can run on the same computer without interfering with each other.

### Annotations (in Java)
**What they are:** Special markers you add to code that give instructions to the framework.

**Simple explanation:** Think of annotations like post-it notes with instructions:
- You stick them on things to say "handle this specially"
- The framework reads these notes and does something special

**Example:**
```java
@EnableEurekaServer  // This post-it note says "make this a Eureka server"
public class DiscoveryServiceApplication {
    // Your code here
}
```

Common Spring annotations:
- `@SpringBootApplication`: "This is the main starting point"
- `@EnableEurekaServer`: "Enable Eureka server features"
- `@RestController`: "This class handles web requests"
- `@Service`: "This class contains business logic"

### YAML (application.yml)
**What it is:** A human-friendly format for writing configuration files.

**Simple explanation:** Configuration files are like settings for your application. YAML is a way to write these settings that's easy to read.

**Example:**
```yaml
server:
  port: 8761              # Run on port 8761
  
spring:
  application:
    name: discovery-service   # Name of this service
    
eureka:
  client:
    register-with-eureka: false   # Don't register with yourself
```

**Why YAML?** It's easier to read than XML (an older format) because it uses indentation instead of angle brackets.

---

## Step 3: Set Up API Gateway

### API Gateway
**What it is:** The single entry point for all requests to your microservices.

**Simple explanation:** Think of a large company:

**Without gateway:** Customers need to know the direct phone number of Sales (555-1234), Support (555-5678), Billing (555-9012). Confusing!

**With gateway:** Customers call one number (555-0000), and the receptionist transfers them to the right department.

**API Gateway does:**
1. **Routing:** Sends requests to the right microservice
   - Request to `/api/products` → goes to product-service
   - Request to `/api/users` → goes to user-service
2. **Security:** Checks if users are logged in before allowing requests
3. **Load balancing:** If you have multiple instances of a service, it distributes requests evenly
4. **Rate limiting:** Prevents abuse by limiting requests per user

### Spring Cloud Gateway
**What it is:** Spring's implementation of an API Gateway.

**Simple explanation:** It's a pre-built gateway with all the features you need, so you don't have to write routing logic from scratch.

**Configuration example:**
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://USER-SERVICE      # lb = load balanced
          predicates:
            - Path=/api/users/**      # Match these URLs
```

Translation: "Any request to `/api/users/...` should go to the user-service"

### Routes
**What they are:** Rules that define where to send incoming requests.

**Simple explanation:** Routes are like signs at an intersection:
- "Turn left for Products" → `/api/products/**` → product-service
- "Turn right for Users" → `/api/users/**` → user-service
- "Straight for Media" → `/api/media/**` → media-service

**Pattern matching:**
- `/api/products` → Exact match
- `/api/products/**` → Match everything starting with `/api/products/`
  - `/api/products/123` ✓
  - `/api/products/123/images` ✓

### CORS (Cross-Origin Resource Sharing)
**What it is:** A security feature in browsers that controls which websites can access your API.

**Simple explanation:** Imagine your API is a private club:

**Without CORS:** Anyone from any website can try to access your API. If a hacker creates a malicious website, they could try to steal user data.

**With CORS:** You create a guest list. Only approved websites can access your API:
- ✓ Allowed: Your Angular app at `http://localhost:4200`
- ✗ Blocked: Random hacker site at `http://evil-site.com`

**Browser behavior:**
- Your Angular app (running on `localhost:4200`) makes a request to your API (running on `localhost:8080`)
- Browser: "Hey API, can localhost:4200 access you?"
- API: "Let me check my CORS settings... yes, allowed!"

**Configuration:**
```java
@Configuration
public class CorsConfig {
    @Bean
    public CorsWebFilter corsWebFilter() {
        // Allow requests from your Angular app
        allowedOrigins.add("http://localhost:4200");
    }
}
```

### JWT (JSON Web Token)
**What it is:** A secure way to verify user identity without storing session information on the server.

**Simple explanation:** Like a VIP wristband at a concert:

**Traditional approach (sessions):** 
- You show your ticket at the entrance
- Security gives you a stamp on your hand
- Every time you move around, security checks their records to verify you paid

**JWT approach:**
- You show your ticket at the entrance
- Security gives you a special wristband with encoded information (your name, seat number, expiration time)
- The wristband itself proves you paid - no need to check records
- Each area verifies the wristband without calling back to the entrance

**JWT structure:**
```
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiIxMjMifQ.aBcDeFgHiJkLmNoPqRsTuVwXyZ
       Header          .      Payload      .    Signature
```

- **Header:** Type of token and encryption method
- **Payload:** Your data (userId, role, expiration)
- **Signature:** Proves the token hasn't been tampered with

**Using JWT:**
1. User logs in with username/password
2. Server creates a JWT and sends it to user
3. User stores JWT (in browser)
4. For each request, user sends JWT in headers
5. Server verifies JWT and allows access

### Rate Limiting
**What it is:** Restricting how many requests a user can make in a time period.

**Simple explanation:** Like a buffet restaurant:

**Without rate limiting:** One person could take ALL the food, leaving nothing for others. Or someone could make your server crash by sending millions of requests.

**With rate limiting:** "You can make 100 requests per minute. After that, wait."

**Benefits:**
- Prevents abuse and attacks
- Ensures fair usage for all users
- Protects your servers from overload

**Example configuration:**
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 10  # 10 requests
                redis-rate-limiter.burstCapacity: 20   # per second
```

---

## Step 4: Configure Kafka Infrastructure

### Kafka
**What it is:** A messaging system that lets services communicate asynchronously (without waiting for each other).

**Simple explanation:** Think about communication methods:

**Synchronous (phone call):**
- You call someone
- You WAIT until they answer
- You talk, they respond immediately
- If they don't answer, you're stuck waiting

**Asynchronous (email/text):**
- You send a message
- You continue with your work
- They read and respond when they can
- Multiple people can receive the same message

**Kafka is like a super-fast email system for services:**
- One service sends a message to Kafka
- Kafka stores it temporarily
- Other services read the message when they're ready
- No one has to wait for anyone else

### Real-world example:
**Scenario:** User uploads a product image

**Without Kafka (synchronous):**
```
User uploads image 
  → Media Service receives and saves it (2 seconds)
  → WAIT for Product Service to update database (1 second)
  → WAIT for Email Service to notify seller (3 seconds)
  → WAIT for Analytics Service to log event (1 second)
Total: 7 seconds (user waits the whole time!)
```

**With Kafka (asynchronous):**
```
User uploads image 
  → Media Service saves it (2 seconds)
  → Media Service sends message to Kafka "image uploaded"
  → User gets immediate response! (2 seconds total)
  
Meanwhile, in the background:
  → Product Service reads message and updates db
  → Email Service reads message and sends notification
  → Analytics Service reads message and logs event
(All happening independently, user doesn't wait)
```

### Docker Compose
**What it is:** A tool to run multiple applications (containers) together with one command.

**Simple explanation:** Imagine setting up a development environment:

**Manual way:**
1. Install MongoDB
2. Configure MongoDB settings
3. Start MongoDB
4. Install Kafka
5. Configure Kafka settings
6. Start Kafka
7. Install Zookeeper (Kafka dependency)
8. Configure Zookeeper
9. Start Zookeeper
... and so on (exhausting!)

**Docker Compose way:**
```bash
docker-compose up
```
Done! Everything starts automatically with the right settings.

**What Docker Compose does:**
- Defines all services in one file (docker-compose.yml)
- Starts everything with one command
- Connects services together
- Stops everything with one command

**Example docker-compose.yml:**
```yaml
version: '3'
services:
  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"
  
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    
  kafka:
    image: confluentinc/cp-kafka:latest
    ports:
      - "9092:9092"
    depends_on:
      - zookeeper
```

### Topics (in Kafka)
**What they are:** Categories or channels where messages are published.

**Simple explanation:** Like radio stations:
- FM 101.1: Music station
- FM 102.5: News station
- FM 103.7: Sports station

Kafka topics:
- `product-created`: Messages about new products
- `product-updated`: Messages about product changes
- `image-uploaded`: Messages about new images

**How it works:**
1. **Producer** (sender): Media Service uploads an image and sends a message to the `image-uploaded` topic
2. **Kafka**: Stores the message
3. **Consumer** (receiver): Product Service listens to `image-uploaded` topic and processes new messages

**Why use topics?** So services only receive messages they care about. Product Service doesn't need to know about `user-registered` events, so it doesn't listen to that topic.

### Producer
**What it is:** A service that sends (publishes) messages to Kafka.

**Simple explanation:** Like a radio station that broadcasts messages.

**Example code:**
```java
@Service
public class MediaService {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    public void uploadImage(MultipartFile file) {
        // Save image
        saveImageToStorage(file);
        
        // Notify other services
        kafkaTemplate.send("image-uploaded", "New image: " + file.getName());
    }
}
```

### Consumer
**What it is:** A service that receives (subscribes to) messages from Kafka.

**Simple explanation:** Like a radio receiver tuned to a specific station.

**Example code:**
```java
@Service
public class ProductService {
    
    @KafkaListener(topics = "image-uploaded")
    public void handleImageUpload(String message) {
        // Do something when image is uploaded
        System.out.println("Received: " + message);
        updateProductImages(message);
    }
}
```

### Zookeeper
**What it is:** A service that helps Kafka manage itself (Kafka dependency).

**Simple explanation:** Like a manager that helps coordinate Kafka:
- Keeps track of all Kafka brokers (servers)
- Manages configurations
- Handles leader elections if a broker fails

**For beginners:** You don't need to understand Zookeeper deeply. Just know:
- Kafka needs Zookeeper to run
- Start Zookeeper before Kafka
- It runs in the background doing management tasks

**Note:** Newer versions of Kafka are removing the Zookeeper requirement, but it's still common in current setups.

---

## Step 5: Database Setup

### MongoDB
**What it is:** A NoSQL database that stores data in flexible, JSON-like documents.

**Simple explanation:** Think of data storage:

**Traditional database (SQL):** Like an Excel spreadsheet
- Strict rows and columns
- Every row must have the same columns
- Rigid structure

**MongoDB (NoSQL):** Like a filing cabinet with flexible folders
- Each document can have different fields
- Easy to add new fields
- Flexible structure

**Example:**

**User document in MongoDB:**
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "John Doe",
  "email": "john@example.com",
  "password": "$2a$10$hashed...",
  "role": "SELLER",
  "avatar": "https://example.com/images/avatar.jpg",
  "createdAt": "2026-03-05T10:30:00Z"
}
```

**Why MongoDB for this project?**
- Flexible schema (easy to add new fields later)
- Good performance for read-heavy applications
- Works well with modern web applications
- Stores data in JSON format (same as JavaScript/TypeScript)

### Database vs Collection vs Document
**Understanding the hierarchy:**

```
MongoDB Server (the software running on your computer)
  └── Database: user_db
       ├── Collection: users
       │    ├── Document: {name: "Alice", role: "CLIENT"}
       │    └── Document: {name: "Bob", role: "SELLER"}
       └── Collection: sessions
            └── Document: {userId: "123", token: "abc..."}
```

**Real-world analogy:**
- **Server**: A library building
- **Database**: A section (Fiction, Non-fiction, Reference)
- **Collection**: A bookshelf in that section
- **Document**: A single book on that shelf

### Separate Databases for Each Service
**Why?** Remember, microservices should be independent.

**Bad approach (shared database):**
```
MongoDB Server
  └── ecommerce_db
       ├── users collection    (used by user-service)
       ├── products collection (used by product-service)
       └── media collection    (used by media-service)
```

Problem: Services are coupled. If you change the users collection, you might break other services.

**Good approach (separate databases):**
```
MongoDB Server
  ├── user_db
  │    └── users collection    (only user-service accesses)
  ├── product_db
  │    └── products collection (only product-service accesses)
  └── media_db
       └── media collection    (only media-service accesses)
```

Benefits:
- Each service owns its data
- Services can't accidentally modify other services' data
- You can use different database technologies for different services
- Easier to scale (each database can be on a different server)

### Schema Design
**What it is:** Planning what data to store and how to structure it.

**Simple explanation:** Like planning what information to put on a form.

**User schema:**
```javascript
{
  id: String,             // Unique identifier: "507f1f77bcf86cd799439011"
  name: String,           // Full name: "Jane Doe"
  email: String,          // Contact: "jane@example.com"
  password: String,       // Hashed password: "$2a$10$..."
  role: Enum,            // Either "CLIENT" or "SELLER"
  avatar: String,        // URL to avatar image
  createdAt: Date,       // When user registered
  updatedAt: Date        // When profile last updated
}
```

**Product schema:**
```javascript
{
  id: String,            // Unique identifier
  name: String,          // Product name: "Laptop"
  description: String,   // Details: "15-inch gaming laptop..."
  price: Double,         // Price: 1299.99
  quantity: Integer,     // Stock: 5
  userId: String,        // Who created this (seller's ID)
  imageUrls: Array,      // ["http://..img1.jpg", "http://..img2.jpg"]
  createdAt: Date,
  updatedAt: Date
}
```

**Media schema:**
```javascript
{
  id: String,           // Unique identifier
  fileName: String,     // Original name: "laptop-photo.jpg"
  filePath: String,     // Where stored: "/uploads/abc123.jpg"
  productId: String,    // Which product (optional, can be null)
  userId: String,       // Who uploaded (seller's ID)
  contentType: String,  // MIME type: "image/jpeg"
  size: Integer,        // File size in bytes: 1048576
  uploadedAt: Date
}
```

### Field Types
- **String**: Text data (names, descriptions, URLs)
- **Integer**: Whole numbers (quantity: 5, not 5.5)
- **Double**: Decimal numbers (price: 19.99)
- **Date**: Timestamps (when something happened)
- **Array**: List of items (multiple image URLs)
- **Enum**: Limited options (role can only be CLIENT or SELLER)

---

## Key Concepts Summary

### Microservice Architecture Benefits
1. **Independence**: Each service can be developed and deployed separately
2. **Scalability**: Scale only the services that need it (if Media Service gets lots of uploads, scale only that)
3. **Reliability**: If one service crashes, others keep working
4. **Technology flexibility**: Use different technologies for different services
5. **Team autonomy**: Different teams can work on different services

### Service Communication
1. **Synchronous (direct calls)**: 
   - Gateway calls User Service to check authentication
   - Fast, but both services must be available
   
2. **Asynchronous (Kafka messages)**:
   - Product Service sends "product created" event
   - Other services process it when ready
   - Slower, but more resilient

### Development Workflow (Phase 1)
```
1. Set up project structure (folders and files)
2. Configure Eureka (so services can find each other)
3. Configure Gateway (single entry point)
4. Set up Kafka (for messaging between services)
5. Install MongoDB (for data storage)
6. Configure each service to connect to these tools
```

---

## Tools You'll Actually Use

### For Development
- **IDE**: IntelliJ IDEA (for Java) or VS Code (for everything)
- **Terminal**: To run commands
- **Postman**: To test your APIs
- **MongoDB Compass**: Visual tool for MongoDB
- **Docker Desktop**: To run containers

### File Extensions You'll See
- `.java`: Java code files
- `.yml` or `.yaml`: Configuration files
- `.xml`: Maven configuration (pom.xml)
- `.properties`: Alternative config format
- `.md`: Documentation (Markdown)
- `.gitignore`: Git ignore rules

### Commands You'll Run
```bash
# Maven commands
mvn clean install          # Download dependencies and build
mvn spring-boot:run       # Start a service

# Git commands
git init                  # Initialize repository
git add .                 # Stage all changes
git commit -m "message"   # Save changes
git push                  # Upload to GitHub

# Docker Compose commands
docker-compose up         # Start all services
docker-compose down       # Stop all services
docker-compose logs       # View logs
```

---

## Learning Path Recommendation

**If you're completely new to programming:**

1. **First, learn Java basics** (2-3 weeks):
   - Variables, data types
   - Loops and conditions
   - Functions/methods
   - Object-oriented programming (classes, objects)

2. **Then learn Spring Boot basics** (2 weeks):
   - What is a web application?
   - Creating REST APIs
   - Connecting to databases

3. **Start building** (follow this plan):
   - Begin with Phase 1
   - Don't rush - understand each concept
   - Build one service at a time
   - Test frequently

**Resources:**
- Java: "Java for Beginners" on YouTube
- Spring Boot: Official Spring Boot guides (spring.io/guides)
- MongoDB: MongoDB University (free courses)
- Docker: Docker's official getting started guide

**Remember**: It's okay not to understand everything at once. Focus on:
1. Getting things working first
2. Understanding why they work later
3. Improving and optimizing eventually

Good luck with your project! 🚀
