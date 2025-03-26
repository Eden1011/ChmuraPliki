#!/bin/bash

# Nazwa kontenera
CONTAINER_NAME="nodejs-nginx-proxy"
NODE_PORT=3000
NGINX_PORT=80
HTTPS_PORT=443

# Tworzenie katalogów tymczasowych
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/nginx-conf"
mkdir -p "$TEMP_DIR/node-app"
mkdir -p "$TEMP_DIR/ssl"
mkdir -p "$TEMP_DIR/cache"

# Tworzenie prostej aplikacji Node.js
cat >"$TEMP_DIR/node-app/app.js" <<'EOF'
const http = require('http');

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html');
  res.end('<h1>Hello from Node.js!</h1><p>This page is served by a Node.js application behind Nginx.</p>');
});

server.listen(3000, '0.0.0.0', () => {
  console.log('Node.js server running on port 3000');
});
EOF

cat >"$TEMP_DIR/node-app/package.json" <<'EOF'
{
  "name": "node-app",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  }
}
EOF

# Tworzenie konfiguracji Nginx
cat >"$TEMP_DIR/nginx-conf/nginx.conf" <<'EOF'
user nginx;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Ustawienia logowania
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent"';
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    # Ustawienia cache
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=100m inactive=60m;
    proxy_cache_key "$scheme$request_method$host$request_uri";
    
    # Ustawienia SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Ustawienia HTTP
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server {
        listen 80;
        listen [::]:80;
        
        # Przekierowanie HTTP na HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;
        
        location / {
            proxy_pass http://localhost:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Konfiguracja cache
            proxy_cache my_cache;
            proxy_cache_valid 200 10m;
            proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
            add_header X-Cache-Status $upstream_cache_status;
        }
    }
}
EOF

# Generowanie certyfikatu SSL
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$TEMP_DIR/ssl/nginx.key" \
  -out "$TEMP_DIR/ssl/nginx.crt" \
  -subj "/C=PL/ST=State/L=City/O=Organization/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# Ustawienie uprawnień dla katalogu cache
chmod 777 "$TEMP_DIR/cache"

# Tworzenie Dockerfile
cat >"$TEMP_DIR/Dockerfile" <<'EOF'
FROM nginx:alpine

# Instalacja Node.js i openssl
RUN apk add --update nodejs npm openssl

# Konfiguracja Nginx
COPY nginx-conf/nginx.conf /etc/nginx/nginx.conf

# Konfiguracja SSL
COPY ssl/nginx.crt /etc/nginx/ssl/nginx.crt
COPY ssl/nginx.key /etc/nginx/ssl/nginx.key

# Konfiguracja aplikacji Node.js
WORKDIR /app
COPY node-app/package.json .
COPY node-app/app.js .

# Tworzenie i konfiguracja katalogu cache
RUN mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx

# Skrypt startowy
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80 443 3000
CMD ["/start.sh"]
EOF

# Tworzenie skryptu startowego
cat >"$TEMP_DIR/start.sh" <<'EOF'
#!/bin/sh
# Uruchomienie aplikacji Node.js w tle
cd /app && npm start &

# Uruchomienie Nginx
nginx -g "daemon off;"
EOF

# Budowanie i uruchamianie kontenera
echo "Budowanie obrazu Docker..."
docker build -t nodejs-nginx-proxy "$TEMP_DIR"

# Zatrzymanie i usunięcie istniejącego kontenera, jeśli istnieje
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Uruchomienie kontenera
echo "Uruchamianie kontenera..."
docker run -d --name "$CONTAINER_NAME" \
  -p "$NGINX_PORT:80" \
  -p "$HTTPS_PORT:443" \
  -p "$NODE_PORT:3000" \
  nodejs-nginx-proxy

echo "Kontener $CONTAINER_NAME uruchomiony."
echo "Aplikacja Node.js dostępna pod adresem: http://localhost:$NODE_PORT"
echo "Serwer Nginx dostępny pod adresem: http://localhost:$NGINX_PORT (przekieruje na HTTPS)"
echo "Serwer Nginx z SSL dostępny pod adresem: https://localhost:$HTTPS_PORT"

# Sprzątanie
rm -rf "$TEMP_DIR"
