#!/bin/bash

# 404 Error Debugging Script
# This script helps diagnose 404 errors in the multi-service architecture

set -e

echo "=== 404 Error Debugging Guide ==="
echo "Date: $(date)"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info "Checking Docker services status..."

# Check if Docker is running
if docker info >/dev/null 2>&1; then
    print_success "Docker daemon is running"
    
    # Check container status
    print_info "Checking container status..."
    if docker-compose ps 2>/dev/null; then
        print_info "Container status displayed above"
    else
        print_error "Failed to get container status"
    fi
    
    # Check if containers are running
    CONTAINERS=$(docker-compose ps -q 2>/dev/null || echo "")
    if [ -n "$CONTAINERS" ]; then
        print_info "Checking individual container health..."
        
        # Check Nginx
        if docker-compose exec -T nginx nginx -t 2>/dev/null; then
            print_success "Nginx configuration is valid"
        else
            print_error "Nginx configuration has issues"
        fi
        
        # Check if services are responding internally
        print_info "Checking internal service connectivity..."
        
        # Test Keycloak
        if docker-compose exec -T nginx wget -q --spider http://keycloak:8080/auth 2>/dev/null; then
            print_success "Keycloak is responding internally"
        else
            print_warning "Keycloak may not be ready or responding"
        fi
        
        # Test OpenWebUI
        if docker-compose exec -T nginx wget -q --spider http://openwebui:8080 2>/dev/null; then
            print_success "OpenWebUI is responding internally"
        else
            print_warning "OpenWebUI may not be ready or responding"
        fi
        
        # Test Code Server
        if docker-compose exec -T nginx wget -q --spider http://code-server:8080 2>/dev/null; then
            print_success "Code Server is responding internally"
        else
            print_warning "Code Server may not be ready or responding"
        fi
        
        # Test FastAPI
        if docker-compose exec -T nginx wget -q --spider http://fastapi:8000 2>/dev/null; then
            print_success "FastAPI is responding internally"
        else
            print_warning "FastAPI may not be ready or responding"
        fi
        
    else
        print_error "No containers are running"
        print_info "Start containers with: docker-compose up -d --build"
    fi
    
else
    print_error "Docker daemon is not running"
    print_info "Start Docker daemon first"
fi

echo
print_info "=== Common 404 Error Causes and Solutions ==="
echo

echo "1. Services not started:"
echo "   Solution: docker-compose up -d --build"
echo

echo "2. Services still initializing:"
echo "   - Keycloak takes 2-3 minutes to fully start"
echo "   - Check logs: docker-compose logs -f keycloak"
echo "   - Wait for 'Keycloak [version] started' message"
echo

echo "3. Wrong URL paths:"
echo "   ✓ Correct: http://localhost:26280/auth/admin"
echo "   ✗ Wrong:   http://localhost:26280/admin"
echo "   ✓ Correct: http://localhost:26280/webui"
echo "   ✓ Correct: http://localhost:26280/vscode"
echo "   ✓ Correct: http://localhost:26280/toy"
echo

echo "4. Nginx configuration issues:"
echo "   - Check: docker-compose logs nginx"
echo "   - Test config: docker-compose exec nginx nginx -t"
echo

echo "5. Service dependencies not ready:"
echo "   - Keycloak needs PostgreSQL"
echo "   - Check: docker-compose logs postgres"
echo "   - Check: docker-compose logs keycloak"
echo

echo "6. Port conflicts:"
echo "   - Currently using ports 26280/26443"
echo "   - Check if ports are free: netstat -tuln | grep 26280"
echo

echo "7. Authentication redirection:"
echo "   - First access may redirect to Keycloak login"
echo "   - Use test credentials: testuser/testpassword"
echo

print_info "=== Debugging Commands ==="
echo
echo "# Check all logs:"
echo "docker-compose logs -f"
echo
echo "# Check specific service:"
echo "docker-compose logs -f [nginx|keycloak|postgres|openwebui|code-server|fastapi]"
echo
echo "# Test internal connectivity:"
echo "docker-compose exec nginx wget -O- http://keycloak:8080/auth/realms/master"
echo
echo "# Check Nginx access logs:"
echo "docker-compose exec nginx tail -f /var/log/nginx/access.log"
echo
echo "# Check Nginx error logs:"
echo "docker-compose exec nginx tail -f /var/log/nginx/error.log"
echo
echo "# Restart specific service:"
echo "docker-compose restart [service-name]"
echo
echo "# Rebuild and restart all:"
echo "docker-compose down && docker-compose up -d --build"
echo

print_info "=== Quick Health Check URLs ==="
echo
echo "Try these URLs in order:"
echo "1. http://localhost:26280/health (Nginx health check)"
echo "2. http://localhost:26280/auth/realms/master (Keycloak master realm)"
echo "3. http://localhost:26280/auth/admin (Keycloak admin - should redirect to login)"
echo "4. http://localhost:26280/toy/health (FastAPI health check)"
echo "5. http://localhost:26280/webui (OpenWebUI - requires auth)"
echo "6. http://localhost:26280/vscode (Code Server - requires auth)"

echo
print_success "Debug script completed! Check the suggestions above."
