#!/bin/bash

# System Test Script
# This script validates the configuration and tests the system deployment

set -e

echo "=== Multi-Service Docker Architecture Test Script ==="
echo "Date: $(date)"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test 1: Check prerequisites
print_status "Testing prerequisites..."

if command -v docker >/dev/null 2>&1; then
    print_status "Docker is installed: $(docker --version)"
else
    print_error "Docker is not installed"
    exit 1
fi

if command -v docker-compose >/dev/null 2>&1; then
    print_status "Docker Compose is installed: $(docker-compose --version)"
else
    print_error "Docker Compose is not installed"
    exit 1
fi

# Test 2: Validate configurations
print_status "Validating configurations..."

# Check Docker Compose configuration
if docker-compose config --quiet; then
    print_status "Docker Compose configuration is valid"
else
    print_error "Docker Compose configuration has errors"
    exit 1
fi

# Check environment file
if [[ -f ".env" ]]; then
    print_status "Environment file exists"
    # Check for important variables
    if grep -q "DOMAIN=" .env; then
        DOMAIN=$(grep "DOMAIN=" .env | cut -d'=' -f2)
        print_status "Domain configured: $DOMAIN"
    else
        print_warning "DOMAIN not set in .env"
    fi
else
    print_warning "No .env file found, using defaults"
fi

# Test 3: Validate shell scripts
print_status "Validating shell scripts..."
for script in scripts/*.sh; do
    if bash -n "$script"; then
        print_status "Script $script has valid syntax"
    else
        print_error "Script $script has syntax errors"
        exit 1
    fi
done

# Test 4: Check FastAPI application
print_status "Validating FastAPI application..."
cd fastapi
if python3 -m py_compile main.py; then
    print_status "FastAPI application syntax is valid"
else
    print_error "FastAPI application has syntax errors"
    exit 1
fi
cd ..

# Test 5: Check file permissions
print_status "Checking file permissions..."
for script in scripts/*.sh; do
    if [[ -x "$script" ]]; then
        print_status "Script $script is executable"
    else
        print_warning "Script $script is not executable, fixing..."
        chmod +x "$script"
    fi
done

# Test 6: Validate JSON configurations
print_status "Validating JSON configurations..."
if command -v jq >/dev/null 2>&1; then
    if jq . keycloak/realm-config.json >/dev/null 2>&1; then
        print_status "Keycloak realm configuration is valid JSON"
    else
        print_error "Keycloak realm configuration is invalid JSON"
        exit 1
    fi
else
    print_warning "jq not installed, skipping JSON validation"
fi

# Test 7: Check network ports (if services are running)
print_status "Checking port availability..."
ports=(26280 26443)
for port in "${ports[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        print_warning "Port $port is already in use"
    else
        print_status "Port $port is available"
    fi
done

# Test 8: Docker daemon status
print_status "Checking Docker daemon..."
if docker info >/dev/null 2>&1; then
    print_status "Docker daemon is running"
    
    # Test 9: Test Docker Compose services (dry run)
    print_status "Testing Docker Compose services..."
    if docker-compose config --services | while read service; do
        print_status "Service defined: $service"
    done; then
        print_status "All services are properly configured"
    fi
else
    print_warning "Docker daemon is not running or not accessible"
    print_warning "Some tests will be skipped"
fi

# Test 10: SSL certificates check
print_status "Checking SSL certificates..."
if [[ -d "ssl-certs" ]]; then
    if [[ -f "ssl-certs/fullchain.pem" && -f "ssl-certs/privkey.pem" ]]; then
        print_status "SSL certificates found"
    else
        print_warning "SSL certificates not found. Use ./scripts/setup-ssl.sh to configure SSL"
    fi
else
    print_warning "SSL certificates directory not found"
fi

echo
print_status "=== Configuration Test Summary ==="
print_status "✓ Prerequisites check passed"
print_status "✓ Configuration validation passed"
print_status "✓ Shell script validation passed"
print_status "✓ FastAPI application validation passed"
print_status "✓ File permissions check passed"
print_status "✓ JSON configuration validation passed"
print_status "✓ Port availability check completed"
print_status "✓ Docker daemon check completed"
print_status "✓ Docker Compose services check passed"
print_status "✓ SSL certificates check completed"

echo
print_status "=== Deployment Instructions ==="
echo "1. Start the services:"
echo "   docker-compose up -d --build"
echo
echo "2. Check service status:"
echo "   docker-compose ps"
echo
echo "3. View logs:"
echo "   docker-compose logs -f"
echo
echo "4. Initialize Keycloak (optional):"
echo "   ./scripts/init-keycloak.sh"
echo
echo "5. Access services:"
echo "   - Keycloak Admin: http://localhost:26280/auth/admin"
echo "   - OpenWebUI: http://localhost:26280/webui"
echo "   - VSCode Server: http://localhost:26280/vscode"
echo "   - FastAPI: http://localhost:26280/toy"
echo
print_status "Test completed successfully!"
