# Buy01 E-Commerce Microservices Platform

A full-stack e-commerce platform built with Spring Boot microservices and Angular frontend.

## Architecture

This project consists of the following microservices:

- **Discovery Service** (Port 8761): Netflix Eureka server for service discovery
- **API Gateway** (Port 8080): Spring Cloud Gateway for routing and security
- **User Service** (Port 8081): User authentication and profile management
- **Product Service** (Port 8082): Product catalog management
- **Media Service** (Port 8083): Image upload and management

## Technologies

### Backend
- Java 17
- Spring Boot 3.2.0
- Spring Cloud 2023.0.0
- MongoDB
- Apache Kafka
- Spring Security + JWT
- Netflix Eureka
- Spring Cloud Gateway

### Infrastructure
- Docker & Docker Compose
- Kafka & Zookeeper
- MongoDB

## Prerequisites

- Java 17+
- Maven 3.6+
- Docker & Docker Compose
- Node.js 18+ (for Angular frontend)

## Quick Start

### 1. Start Infrastructure Services

```bash
docker-compose up -d
```

This will start:
- MongoDB (Port 27017)
- Kafka (Port 9092)
- Zookeeper (Port 2181)

### 2. Build All Services

```bash
mvn clean install
```

### 3. Start Services in Order

```bash
# 1. Start Discovery Service (Eureka)
cd discovery-service
mvn spring-boot:run

# 2. Start API Gateway (wait for Eureka to be ready)
cd api-gateway
mvn spring-boot:run

# 3. Start Microservices
cd user-service
mvn spring-boot:run

cd product-service
mvn spring-boot:run

cd media-service
mvn spring-boot:run
```

### 4. Access Services

- Eureka Dashboard: http://localhost:8761
- API Gateway: http://localhost:8080
- User Service: http://localhost:8081
- Product Service: http://localhost:8082
- Media Service: http://localhost:8083

## Project Structure

```
buy01-own/
├── discovery-service/       # Eureka Server
├── api-gateway/            # Spring Cloud Gateway
├── user-service/           # User authentication & management
├── product-service/        # Product catalog
├── media-service/          # Image management
├── frontend/               # Angular application (to be added)
├── docker-compose.yml      # Infrastructure services
└── pom.xml                # Parent POM
```

## Development

### Running Individual Services

Each service can be run independently using:

```bash
cd <service-name>
mvn spring-boot:run
```

### Environment Variables

Each service supports configuration via environment variables or application.yml files.

## API Documentation

Once services are running, access Swagger UI at:
- User Service: http://localhost:8081/swagger-ui.html
- Product Service: http://localhost:8082/swagger-ui.html
- Media Service: http://localhost:8083/swagger-ui.html

## Testing

Run tests for all services:

```bash
mvn test
```

Run tests for a specific service:

```bash
cd <service-name>
mvn test
```

## License

MIT License
