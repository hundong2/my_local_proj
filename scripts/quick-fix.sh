#!/bin/bash

# Quick fix for connection issues

echo "🔧 Applying quick fixes for service connectivity..."

# Restart services
echo "Restarting services..."
docker-compose restart nginx fastapi

echo "⏳ Waiting 15 seconds for services to stabilize..."
sleep 15

echo "🔍 Testing service connectivity..."

echo "1. Testing Nginx health:"
curl -s -w "HTTP %{http_code}\n" http://localhost:26280/health

echo "2. Testing FastAPI (direct):"
curl -s -w "HTTP %{http_code}\n" http://localhost:26280/toy/

echo "3. Testing Keycloak (master realm):"
curl -s -w "HTTP %{http_code}\n" http://localhost:26280/auth/realms/master

echo "4. Testing internal connectivity from Nginx to services:"
echo "   - Keycloak internal test:"
docker-compose exec -T nginx sh -c 'wget -qO- --timeout=5 http://keycloak:8080/auth/realms/master | head -c 100' 2>/dev/null && echo " [✓ Success]" || echo " [✗ Failed]"

echo "   - FastAPI internal test:"
docker-compose exec -T nginx sh -c 'wget -qO- --timeout=5 http://fastapi:8000/ | head -c 100' 2>/dev/null && echo " [✓ Success]" || echo " [✗ Failed]"

echo "5. Service status:"
docker-compose ps | grep -E "(keycloak|fastapi|nginx|openwebui|code-server)"

echo ""
echo "🌐 Try accessing these URLs:"
echo "   - Dashboard: http://localhost:26280/"
echo "   - Keycloak Admin: http://localhost:26280/auth/admin"
echo "   - FastAPI Health: http://localhost:26280/toy/health"
echo "   - FastAPI Root: http://localhost:26280/toy/"
echo "   - OpenWebUI: http://localhost:26280/webui"
echo "   - VSCode: http://localhost:26280/vscode (password: password123)"
echo ""
echo "📋 If issues persist, check logs:"
echo "   docker-compose logs [service-name]"
