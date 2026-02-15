#!/bin/bash

# Fix Nginx 404 issue by using simplified configuration

echo "🔧 Fixing Nginx configuration for 404 issues..."

# Stop services
echo "Stopping services..."
docker-compose down 2>/dev/null || true

# Backup existing config and use simplified version
echo "Using simplified Nginx configuration..."
cp nginx/conf.d/default.conf nginx/conf.d/default.conf.backup 2>/dev/null || true
cp nginx/conf.d/simple-test.conf nginx/conf.d/default.conf

# Start services
echo "Starting services with new configuration..."
docker-compose up -d --build

echo "⏳ Waiting for services to start..."
sleep 10

echo "🔍 Testing services..."

# Test basic connectivity
echo "Testing Nginx..."
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:26280/health
echo ""

echo "Testing root page..."
curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:26280/
echo ""

echo "✅ Services should now be accessible at:"
echo "   - Main Dashboard: http://localhost:26280/"
echo "   - Health Check: http://localhost:26280/health"
echo "   - Keycloak: http://localhost:26280/auth/admin"
echo "   - FastAPI: http://localhost:26280/toy/"
echo "   - OpenWebUI: http://localhost:26280/webui"
echo "   - VSCode: http://localhost:26280/vscode"
echo ""
echo "📋 Check logs if issues persist:"
echo "   docker-compose logs nginx"
