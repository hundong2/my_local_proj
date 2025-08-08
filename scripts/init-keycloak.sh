#!/bin/bash

# Keycloak Initialization Script

set -e

echo "Initializing Keycloak configuration..."

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to be ready..."
until curl -s -f http://localhost:26280/auth/realms/master/.well-known/openid_configuration > /dev/null 2>&1; do
    echo "Keycloak not ready, waiting..."
    sleep 10
done

echo "Keycloak is ready!"

# Get admin token
echo "Getting admin access token..."
ADMIN_TOKEN=$(curl -s -X POST "http://localhost:26280/auth/realms/master/protocol/openid_connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=${KEYCLOAK_ADMIN:-admin}" \
  -d "password=${KEYCLOAK_ADMIN_PASSWORD:-admin123}" | \
  grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
    echo "Failed to get admin token"
    exit 1
fi

echo "Got admin token"

# Create services realm
echo "Creating services realm..."
curl -s -X POST "http://localhost:26280/auth/admin/realms" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @keycloak/realm-config.json || echo "Realm might already exist"

echo "Keycloak initialization complete!"
echo ""
echo "Access information:"
echo "- Keycloak Admin: http://localhost:26280/auth/admin"
echo "- Username: ${KEYCLOAK_ADMIN:-admin}"
echo "- Password: ${KEYCLOAK_ADMIN_PASSWORD:-admin123}"
echo ""
echo "Test user:"
echo "- Username: testuser"
echo "- Password: testpassword"
