#!/bin/bash

SCRIPT="./nginx_config_docker.sh"
CONFIG="./custom_nginx.conf"

# Czyszczenie
function cleanup {
  docker stop test-default test-custom test-port 2>/dev/null || true
  docker rm test-default test-custom test-port 2>/dev/null || true
}
cleanup

# Test domyślnej konfiguracji
$SCRIPT -p 8080 -n test-default
sleep 2
curl -s http://localhost:8080 | grep -q "Serwer Nginx" && echo "Test domyślny OK" || echo "Test domyślny FAILED"

# Test niestandardowej konfiguracji
$SCRIPT -p 8081 -c "$CONFIG" -n test-custom
sleep 2
curl -s http://localhost:8081/test | grep -q "Test konfiguracji działa" && echo "Test konfiguracji OK" || echo "Test konfiguracji FAILED"
curl -s -I http://localhost:8081 | grep -q "X-Custom-Header" && echo "Test nagłówka OK" || echo "Test nagłówka FAILED"

# Test niestandardowego portu
$SCRIPT -p 8082 -n test-port
sleep 2
curl -s http://localhost:8082 | grep -q "Serwer Nginx" && echo "Test portu OK" || echo "Test portu FAILED"

cleanup
