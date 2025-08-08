#!/bin/bash

# SSL Certificate Setup Script
# Usage: ./setup-ssl.sh <domain>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 example.com"
    exit 1
fi

DOMAIN=$1
SSL_DIR="./ssl-certs"

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

echo "Setting up SSL certificates for domain: $DOMAIN"

# Function to check if docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to setup Let's Encrypt certificates
setup_letsencrypt() {
    echo "Setting up Let's Encrypt certificates..."
    
    # Check if certbot is available
    if ! command -v certbot &> /dev/null; then
        echo "Installing certbot..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y certbot
        elif command -v yum &> /dev/null; then
            sudo yum install -y certbot
        elif command -v docker &> /dev/null; then
            echo "Using certbot via Docker..."
            docker run -it --rm \
                -v "$PWD/ssl-certs:/etc/letsencrypt" \
                -v "$PWD/ssl-certs:/var/lib/letsencrypt" \
                -p 80:80 \
                certbot/certbot certonly --standalone -d "$DOMAIN"
            
            # Copy certificates to expected locations
            cp "$SSL_DIR/live/$DOMAIN/fullchain.pem" "$SSL_DIR/fullchain.pem"
            cp "$SSL_DIR/live/$DOMAIN/privkey.pem" "$SSL_DIR/privkey.pem"
            return
        else
            echo "Cannot install certbot. Please install it manually."
            exit 1
        fi
    fi
    
    # Get certificates
    sudo certbot certonly --standalone -d "$DOMAIN" --email admin@"$DOMAIN" --agree-tos --non-interactive
    
    # Copy certificates
    sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/fullchain.pem"
    sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/privkey.pem"
    
    # Fix permissions
    sudo chown $(whoami):$(whoami) "$SSL_DIR/"*.pem
    chmod 600 "$SSL_DIR/privkey.pem"
    chmod 644 "$SSL_DIR/fullchain.pem"
}

# Function to generate self-signed certificates
setup_selfsigned() {
    echo "Setting up self-signed certificates..."
    
    openssl req -x509 -newkey rsa:4096 -keyout "$SSL_DIR/privkey.pem" -out "$SSL_DIR/fullchain.pem" \
        -days 365 -nodes -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"
    
    chmod 600 "$SSL_DIR/privkey.pem"
    chmod 644 "$SSL_DIR/fullchain.pem"
    
    echo "Self-signed certificates generated."
    echo "WARNING: These certificates are not trusted by browsers."
}

# Main logic
echo "Choose SSL certificate method:"
echo "1) Let's Encrypt (recommended for production)"
echo "2) Self-signed (for development/testing)"
echo "3) Use existing certificates"
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        setup_letsencrypt
        ;;
    2)
        setup_selfsigned
        ;;
    3)
        echo "Please place your certificates in $SSL_DIR/:"
        echo "  - Certificate: $SSL_DIR/fullchain.pem"
        echo "  - Private key: $SSL_DIR/privkey.pem"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Update .env file
if [ -f ".env" ]; then
    sed -i "s/DOMAIN=.*/DOMAIN=$DOMAIN/g" .env
    sed -i "s/SSL_ENABLED=.*/SSL_ENABLED=true/g" .env
else
    echo "Warning: .env file not found. Please update manually."
fi

# Enable SSL configuration in Nginx
echo "Enabling SSL configuration in Nginx..."
if [ -f "nginx/conf.d/ssl.conf" ]; then
    # Remove comment markers to enable SSL configuration
    sed -i 's/^# //g' nginx/conf.d/ssl.conf
fi

# Enable HTTPS redirect in default.conf
if [ -f "nginx/conf.d/default.conf" ]; then
    sed -i 's/# return 301 https/return 301 https/g' nginx/conf.d/default.conf
fi

echo "SSL setup complete!"
echo "Certificates are located in: $SSL_DIR"
echo "Please restart the services: docker-compose restart nginx"
