#!/bin/bash

# Configuration
AWS_REGION="eu-central-1"
ECR_REPOSITORY_NAME="django-on-lambda-docker-app"
IMAGE_TAG="latest"
AWS_ACCOUNT_ID="690431608027"

export AWS_PAGER=""

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
docker buildx build --platform linux/arm64 --provenance false -t $ECR_REPOSITORY_NAME:$IMAGE_TAG .
check_status "Docker build"

# Tag image for ECR
print_status "Tagging image for ECR..."
docker tag $ECR_REPOSITORY_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:$IMAGE_TAG
check_status "Image tagging"

# Push to ECR
print_status "Pushing image to ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:$IMAGE_TAG
check_status "Image push"

# Update Lambda function
print_status "Updating Lambda function..."
aws lambda update-function-code \
    --region $AWS_REGION \
    --function-name $ECR_REPOSITORY_NAME \
    --image-uri $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:$IMAGE_TAG
check_status "Lambda function update"

# Wait for Lambda update to complete
print_status "Waiting for Lambda update to complete..."
aws lambda wait function-updated \
    --region $AWS_REGION \
    --function-name $ECR_REPOSITORY_NAME
check_status "Lambda update completion"

# Verify the update
print_status "Verifying Lambda function configuration..."
aws lambda get-function \
    --region $AWS_REGION \
    --function-name $ECR_REPOSITORY_NAME \
    --query 'Configuration.[LastUpdateStatus,State,LastModified]' \
    --output table
check_status "Configuration verification"

echo -e "${GREEN}✓ Process completed successfully!${NC}"

