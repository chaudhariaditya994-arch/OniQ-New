#!/bin/bash
# OnionGuard SSL Setup Script
# Run this on your EC2 instance (16.16.90.16)
# Usage: chmod +x setup-ssl.sh && ./setup-ssl.sh

DOMAIN="onion-guard.duckdns.org"
EMAIL="adikanathaniel@gmail.com"  # Change to your email for Let's Encrypt notifications

echo "=== Step 1: Starting services with HTTP-only nginx ==="
# Use the init config (HTTP only) to get the cert first
cp nginx/nginx-init.conf nginx/default.conf.bak
docker compose down
docker compose up -d --build api-gateway auth-service diagnosis-service treatment-service analytics-service

# Start nginx with HTTP-only config for cert challenge
docker compose run -d --name nginx-init \
  -p 80:80 \
  -v $(pwd)/nginx/nginx-init.conf:/etc/nginx/conf.d/default.conf:ro \
  -v $(pwd)/certbot-var:/var/www/certbot:ro \
  nginx:alpine

echo ""
echo "=== Step 2: Obtaining SSL certificate from Let's Encrypt ==="
docker run --rm \
  -v $(pwd)/certbot-etc:/etc/letsencrypt \
  -v $(pwd)/certbot-var:/var/www/certbot \
  certbot/certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  -d "$DOMAIN"

if [ $? -ne 0 ]; then
  echo ""
  echo "ERROR: Certificate request failed!"
  echo "Make sure:"
  echo "  1. DNS is pointing to this server: nslookup $DOMAIN"
  echo "  2. Port 80 is open in AWS Security Group"
  echo "  3. No other service is using port 80"
  docker stop nginx-init 2>/dev/null
  exit 1
fi

echo ""
echo "=== Step 3: Switching to full HTTPS nginx config ==="
docker stop nginx-init 2>/dev/null
docker rm nginx-init 2>/dev/null

# Now start everything with the full SSL config
docker compose up -d

echo ""
echo "=== Done! ==="
echo "Your API is now available at:"
echo "  https://$DOMAIN"
echo "  https://$DOMAIN/health"
echo ""
echo "SSL auto-renewal is handled by the certbot container."
echo ""
echo "To manually renew: docker compose exec certbot certbot renew"
