#!/bin/bash

# Exit on any error
set -e

echo "🔧 Starting deployment process..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "⚠️  Virtual environment not found. Creating one..."
    python3.12 -m venv venv
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Install requirements
echo "📦 Installing requirements..."
pip install -r requirements.txt --no-cache-dir

# Clean up old package files
echo "🧹 Cleaning up old package files..."
rm -rf package deployment-package.zip

# Collect static files
echo "📂 Collecting static files..."
python manage.py collectstatic --noinput

# Create new package directory
echo "📁 Creating new package directory..."
mkdir package

# Install dependencies to package directory
echo "📥 Installing dependencies to package directory..."
#pip install -r requirements.txt --no-cache-dir --target package/
pip install \
    --platform manylinux2014_x86_64 \
    --target=package \
    --implementation cp \
    --python-version 3.12 \
    --only-binary=:all: \
    --upgrade \
    -r requirements.txt

# Copy application files
echo "📋 Copying application files..."
cp -r core handler.py manage.py package/

# Copy static files
echo "📋 Copying static files..."
cp -r staticfiles package/

# Create zip file
echo "🗜️  Creating deployment package..."
cd package
zip -q -r ../deployment-package.zip .
cd ..

# Apply Terraform changes
echo "🚀 Applying Terraform changes..."
cd terraform
terraform apply #-auto-approve

echo "✅ Deployment complete!"

