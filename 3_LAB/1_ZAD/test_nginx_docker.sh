#!/bin/bash

SCRIPT_PATH="./nginx_docker.sh"

function cleanup {
  echo "Czyszczenie..."
  docker stop nginx-server >/dev/null 2>&1
  docker rm nginx-server >/dev/null 2>&1
  docker stop test-nginx >/dev/null 2>&1
  docker rm test-nginx >/dev/null 2>&1
  docker stop test-nginx-port >/dev/null 2>&1
  docker rm test-nginx-port >/dev/null 2>&1
  docker stop test-nginx-file >/dev/null 2>&1
  docker rm test-nginx-file >/dev/null 2>&1
}

cleanup

function run_test {
  local test_name="$1"
  local expected="$2"
  local port="$3"
  local content="$4"
  local container_name="${5:-nginx-server}"
  local content_file="$6"

  echo "Uruchamianie testu: $test_name"

  if [ -n "$content_file" ]; then
    $SCRIPT_PATH -p "$port" -f "$content_file" -n "$container_name"
  elif [ -n "$content" ]; then
    $SCRIPT_PATH -p "$port" -c "$content" -n "$container_name"
  else
    $SCRIPT_PATH -p "$port" -n "$container_name"
  fi

  sleep 2

  if ! docker ps | grep -q "$container_name"; then
    echo "Test nieudany: Kontener nie działa"
    cleanup
    exit 1
  fi

  local result=$(curl -s "http://localhost:$port")

  if echo "$result" | grep -q "$expected"; then
    echo "Test udany: Znaleziono oczekiwaną zawartość"
  else
    echo "Test nieudany: Nie znaleziono oczekiwanej zawartości"
    echo "Oczekiwano znaleźć: $expected"
    echo "Aktualna zawartość: $result"
    cleanup
    exit 1
  fi
}

echo "=== Test 1: Domyślna zawartość ==="
run_test "Domyślna zawartość" "Domyślna strona Nginx" 8080

echo "=== Test 2: Niestandardowa zawartość ==="
CUSTOM_CONTENT="<html><body><h1>Niestandardowa strona</h1><p>To jest niestandardowa strona.</p></body></html>"
run_test "Niestandardowa zawartość" "Niestandardowa strona" 8081 "$CUSTOM_CONTENT" "test-nginx"

echo "=== Test 3: Niestandardowy port ==="
run_test "Niestandardowy port" "Domyślna strona Nginx" 8082 "" "test-nginx-port"

echo "=== Test 4: Zawartość z pliku ==="
TEMP_HTML_FILE=$(mktemp)
echo "<html><body><h1>Zawartość z pliku</h1><p>Ta zawartość pochodzi z pliku.</p></body></html>" >"$TEMP_HTML_FILE"
run_test "Zawartość z pliku" "Zawartość z pliku" 8083 "" "test-nginx-file" "$TEMP_HTML_FILE"
rm "$TEMP_HTML_FILE"

echo "Wszystkie testy udane!"

cleanup
