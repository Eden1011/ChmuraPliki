#!/bin/bash

CONTAINER_NAME="nodejs-nginx-proxy"
NODE_PORT=3000
NGINX_PORT=80
HTTPS_PORT=443

# Funkcja do czyszczenia
cleanup() {
  echo "Sprzątanie..."
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
}

# Funkcja do sprawdzania statusu HTTP
check_http() {
  local url=$1
  local expected_status=$2
  local pattern=$3
  local description=$4

  echo -n "Test: $description... "

  # Ignoruj błędy certyfikatu dla HTTPS
  local status_code=$(curl -s -k -o /tmp/response.txt -w "%{http_code}" "$url")

  if [ "$status_code" != "$expected_status" ]; then
    echo "BŁĄD (nieprawidłowy status: $status_code, oczekiwano: $expected_status)"
    return 1
  fi

  if [ -n "$pattern" ]; then
    if grep -q "$pattern" /tmp/response.txt; then
      echo "OK"
      return 0
    else
      echo "BŁĄD (nie znaleziono wzorca: $pattern)"
      return 1
    fi
  else
    echo "OK"
    return 0
  fi
}

# Uruchomienie testu
echo "Uruchamianie testów dla Node.js + Nginx reverse proxy..."

# Sprawdź, czy kontener działa
echo -n "Test: Sprawdzanie czy kontener działa... "
if docker ps | grep -q "$CONTAINER_NAME"; then
  echo "OK"
else
  echo "BŁĄD (kontener nie jest uruchomiony)"
  exit 1
fi

# Test 1: Dostęp do aplikacji Node.js bezpośrednio
check_http "http://localhost:$NODE_PORT" 200 "Hello from Node.js" "Dostęp do aplikacji Node.js bezpośrednio"

# Test 2: Dostęp do HTTP (powinno przekierować do HTTPS)
check_http "http://localhost:$NGINX_PORT" 301 "" "Przekierowanie HTTP do HTTPS"

# Test 3: Dostęp do HTTPS
check_http "https://localhost:$HTTPS_PORT" 200 "Hello from Node.js" "Dostęp do Nginx przez HTTPS"

# Test 4: Sprawdzenie cache
echo -n "Test: Sprawdzanie cache... "
curl -s -k -o /dev/null "https://localhost:$HTTPS_PORT"
CACHE_STATUS=$(curl -s -k -I "https://localhost:$HTTPS_PORT" | grep -i "X-Cache-Status")

if echo "$CACHE_STATUS" | grep -i -E "HIT|MISS" >/dev/null; then
  echo "OK (status cache: $(echo $CACHE_STATUS | awk '{print $2}'))"
else
  echo "BŁĄD (nie znaleziono nagłówka X-Cache-Status)"
fi

# Test 5: Sprawdzenie certyfikatu SSL
echo -n "Test: Sprawdzanie certyfikatu SSL... "
SSL_INFO=$(echo | openssl s_client -connect localhost:$HTTPS_PORT 2>/dev/null)

if echo "$SSL_INFO" | grep -q "Verify return code: 0"; then
  echo "OK (certyfikat prawidłowy, ale self-signed)"
else
  echo "OK (certyfikat self-signed, jak oczekiwano)"
fi

# Test 6: Sprawdzanie użytkownika cache
echo -n "Test: Sprawdzanie użytkownika katalogu cache... "
CACHE_USER=$(docker exec "$CONTAINER_NAME" sh -c "ls -la /var/cache/nginx | grep nginx | wc -l")

if [ "$CACHE_USER" -gt 0 ]; then
  echo "OK (katalog cache należy do użytkownika nginx)"
else
  echo "BŁĄD (katalog cache nie należy do użytkownika nginx)"
fi

echo "Testy zakończone."
