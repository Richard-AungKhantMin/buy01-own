#!/bin/bash

# Buy01 E-Commerce Platform - Startup Script
# This script starts all infrastructure services and microservices in the correct order

set -e

echo "🚀 Starting Buy01 E-Commerce Platform..."
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a port is in use
check_port() {
    nc -z localhost $1 2>/dev/null
    return $?
}

# Function to wait for a service to be ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=0

    echo -e "${YELLOW}Waiting for $service_name to be ready on port $port...${NC}"
    
    while ! check_port $port; do
        attempt=$((attempt + 1))
        if [ $attempt -eq $max_attempts ]; then
            echo -e "${RED}ERROR: $service_name failed to start after $max_attempts attempts${NC}"
            exit 1
        fi
        echo -n "."
        sleep 2
    done
    
    echo -e "${GREEN}✓ $service_name is ready!${NC}"
}

# Step 1: Start infrastructure services with Docker Compose
echo "📦 Step 1: Starting infrastructure services (MongoDB, Kafka, Zookeeper)..."
docker-compose up -d

# Wait for infrastructure services
wait_for_service "MongoDB" 27017
wait_for_service "Kafka" 9092
echo ""

# Step 2: Build all services
echo "🔨 Step 2: Building all microservices..."
mvn clean install -DskipTests
echo -e "${GREEN}✓ Build completed!${NC}"
echo ""

# Step 3: Start Discovery Service (Eureka)
echo "🔍 Step 3: Starting Discovery Service (Eureka)..."
cd discovery-service
mvn spring-boot:run > ../logs/discovery-service.log 2>&1 &
DISCOVERY_PID=$!
cd ..
wait_for_service "Discovery Service" 8761
echo ""

# Step 4: Start API Gateway
echo "🌐 Step 4: Starting API Gateway..."
cd api-gateway
mvn spring-boot:run > ../logs/api-gateway.log 2>&1 &
GATEWAY_PID=$!
cd ..
wait_for_service "API Gateway" 8080
echo ""

# Step 5: Start microservices
echo "⚙️  Step 5: Starting microservices..."

# User Service
echo "Starting User Service..."
cd user-service
mvn spring-boot:run > ../logs/user-service.log 2>&1 &
USER_PID=$!
cd ..
wait_for_service "User Service" 8081

# Product Service
echo "Starting Product Service..."
cd product-service
mvn spring-boot:run > ../logs/product-service.log 2>&1 &
PRODUCT_PID=$!
cd ..
wait_for_service "Product Service" 8082

# Media Service
echo "Starting Media Service..."
cd media-service
mvn spring-boot:run > ../logs/media-service.log 2>&1 &
MEDIA_PID=$!
cd ..
wait_for_service "Media Service" 8083

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ All services are running!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📝 Service URLs:"
echo "  • Eureka Dashboard:  http://localhost:8761"
echo "  • API Gateway:       http://localhost:8080"
echo "  • User Service:      http://localhost:8081"
echo "  • Product Service:   http://localhost:8082"
echo "  • Media Service:     http://localhost:8083"
echo "  • Kafka UI:          http://localhost:8090"
echo ""
echo "📋 Process IDs:"
echo "  • Discovery Service: $DISCOVERY_PID"
echo "  • API Gateway:       $GATEWAY_PID"
echo "  • User Service:      $USER_PID"
echo "  • Product Service:   $PRODUCT_PID"
echo "  • Media Service:     $MEDIA_PID"
echo ""
echo "📄 Logs are available in the ./logs directory"
echo ""
echo "To stop all services, run: ./stop-services.sh"
echo ""

# Save PIDs to file for cleanup script
mkdir -p logs
echo "$DISCOVERY_PID" > logs/pids.txt
echo "$GATEWAY_PID" >> logs/pids.txt
echo "$USER_PID" >> logs/pids.txt
echo "$PRODUCT_PID" >> logs/pids.txt
echo "$MEDIA_PID" >> logs/pids.txt
