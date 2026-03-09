#!/bin/bash

# Buy01 E-Commerce Platform - Stop Script
# This script stops all running microservices and infrastructure

echo "🛑 Stopping Buy01 E-Commerce Platform..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Stop Spring Boot services
if [ -f logs/pids.txt ]; then
    echo "Stopping Spring Boot services..."
    while read pid; do
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid
            echo -e "${GREEN}✓ Stopped process $pid${NC}"
        fi
    done < logs/pids.txt
    rm logs/pids.txt
else
    echo "No PIDs file found. Attempting to kill by port..."
    
    # Kill processes on known ports
    for port in 8761 8080 8081 8082 8083; do
        pid=$(lsof -ti:$port)
        if [ ! -z "$pid" ]; then
            kill $pid
            echo -e "${GREEN}✓ Stopped process on port $port${NC}"
        fi
    done
fi

# Stop Docker Compose services
echo "Stopping Docker Compose services..."
docker-compose down

echo -e "${GREEN}✅ All services stopped!${NC}"
