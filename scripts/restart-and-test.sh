#!/bin/bash

# Complete restart and test script

echo "🔄 Restarting all services with fixes..."

# Rebuild FastAPI with health endpoint fix
echo "Building FastAPI with health fix..."
docker-compose build fastapi

# Restart services in order
echo "Restarting services..."
docker-compose restart nginx fastapi

echo "⏳ Waiting 30 seconds for Keycloak to be fully ready..."
echo "(Keycloak was already running, just waiting for readiness)"
sleep 30

echo "🔍 Testing services systematically..."

echo "1. Basic Nginx health:"
curl -s -w "Status: %{http_code}\n" http://localhost:26280/health
echo

echo "2. FastAPI health (should work now):"
curl -s -w "Status: %{http_code}\n" http://localhost:26280/toy/health
echo

echo "3. FastAPI root:"
curl -s http://localhost:26280/toy/ | head -c 100
echo -e "\nStatus: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:26280/toy/)\n"

echo "4. Keycloak master realm:"
curl -s -w "Status: %{http_code}\n" http://localhost:26280/auth/realms/master | head -c 50
echo

echo "5. Internal health checks:"
echo "   - Keycloak internal:" 
curl -s -w "Status: %{http_code}\n" http://localhost:26280/health-check/keycloak | head -c 50
echo
echo "   - FastAPI internal:"
curl -s -w "Status: %{http_code}\n" http://localhost:26280/health-check/fastapi | head -c 50
echo

echo "6. Service status:"
docker-compose ps

echo ""
echo "✅ Test Results Summary:"
echo "If you see 200 status codes above, the services are working!"
echo ""
echo "🌐 Service URLs:"
echo "   - Main Dashboard: http://localhost:26280/"
echo "   - Keycloak Admin: http://localhost:26280/auth/admin"
echo "   - FastAPI: http://localhost:26280/toy/"
echo "   - OpenWebUI: http://localhost:26280/webui"
echo "   - VSCode: http://localhost:26280/vscode"
echo ""
echo "📋 Keycloak credentials: admin / admin123"
echo "📋 VSCode password: password123"
