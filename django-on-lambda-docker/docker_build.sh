#!/bin/bash

# Configuration
AWS_REGION="eu-central-1"
ECR_REPOSITORY_NAME="django-on-lambda-docker-app"
IMAGE_TAG="latest"
AWS_ACCOUNT_ID="690431608027"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${YELLOW}>>> $1${NC}"
}

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# Start the process
print_status "Starting ECR image update process..."

# Authenticate Docker to ECR
print_status "Authenticating with AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
check_status "ECR Authentication"

# Build Docker image
print_status "Building Docker image..."
docker buildx build --no-cache --platform linux/arm64 --provenance false -t $ECR_REPOSITORY_NAME:$IMAGE_TAG .
check_status "Docker build"

# View image size and other details
print_status "Image details:"
docker images | grep $ECR_REPOSITORY_NAME
check_status "Image details"

# Start the container with health check
print_status "Starting container with health check..."
DB_NETWORK=$(docker inspect django-on-lambda-docker-db-1 -f '{{range $k, $v := .NetworkSettings.Networks}}{{printf "%s" $k}}{{end}}')

docker run -d \
    --name health-check-container \
    --network $DB_NETWORK \
    -p 8080:8080 \
    --env-file .env \
    --health-cmd="python -c 'from urllib import request; request.urlopen(\"http://localhost:8080/admin\")'" \
    --health-interval=2s \
    --health-retries=3 \
    --health-timeout=2s \
    $ECR_REPOSITORY_NAME:$IMAGE_TAG
check_status "Container started"

# Wait for health check to pass
print_status "Waiting for health check to pass..."
sleep 3
docker inspect --format='{{json .State.Health.Status}}' health-check-container
docker inspect --format='{{json .State.Health.Status}}' health-check-container | grep -q 'healthy'
docker inspect --format='{{json .State.Health.Status}}' health-check-container | grep -q 'healthy"' && echo -e "${GREEN}✓ Health check passed${NC}" || echo -e "${RED}✗ Health check failed${NC}"
sleep 3
docker logs health-check-container

# Clean up container
print_status "Cleaning up container..."
docker rm -f health-check-container
check_status "Container cleaned up"

echo -e "${GREEN}✓ Process completed successfully!${NC}"

