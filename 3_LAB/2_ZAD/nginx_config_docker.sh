#!/bin/bash

PORT=8080
CONFIG_FILE=""
CONTAINER_NAME="nginx-custom-config"

# Parsowanie argumentów
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -p | --port)
    PORT="$2"
    shift 2
    ;;
  -c | --config)
    CONFIG_FILE="$2"
    shift 2
    ;;
  -n | --name)
    CONTAINER_NAME="$2"
    shift 2
    ;;
  *) shift ;;
  esac
done

# Utwórz tymczasowy katalog
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/html"
echo "<html><body><h1>Serwer Nginx</h1></body></html>" >"$TMP_DIR/html/index.html"

# Obsługa konfiguracji
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
  mkdir -p "$TMP_DIR/conf"
  cp "$CONFIG_FILE" "$TMP_DIR/conf/nginx.conf"
  cat >"$TMP_DIR/Dockerfile" <<EOF
FROM nginx:alpine
COPY html /usr/share/nginx/html
COPY conf/nginx.conf /etc/nginx/nginx.conf
CMD ["nginx", "-g", "daemon off;"]
EOF
else
  cat >"$TMP_DIR/Dockerfile" <<EOF
FROM nginx:alpine
COPY html /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]
EOF
fi

# Zbuduj obraz i uruchom kontener
docker build -t nginx-custom "$TMP_DIR"
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true
docker run -d --name "$CONTAINER_NAME" -p "$PORT:80" nginx-custom

# Posprzątaj
rm -rf "$TMP_DIR"
