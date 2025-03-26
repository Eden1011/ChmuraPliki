#!/bin/bash

PORT=8080
CONTENT="<html><body><h1>Domyślna strona Nginx</h1><p>To jest domyślna strona serwowana przez Nginx.</p></body></html>"
CONTENT_FILE=""
CONTAINER_NAME="nginx-server"

function show_usage {
  echo "Użycie: $0 [opcje]"
  echo "Opcje:"
  echo "  -p, --port PORT        Port do wystawienia (domyślnie: 8080)"
  echo "  -c, --content CONTENT  Treść HTML dla strony"
  echo "  -f, --file FILE        Plik zawierający treść HTML (nadpisuje --content)"
  echo "  -n, --name NAME        Nazwa kontenera (domyślnie: nginx-server)"
  echo "  -h, --help             Pokaż tę pomoc"
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -p | --port)
    PORT="$2"
    shift 2
    ;;
  -c | --content)
    CONTENT="$2"
    shift 2
    ;;
  -f | --file)
    CONTENT_FILE="$2"
    shift 2
    ;;
  -n | --name)
    CONTAINER_NAME="$2"
    shift 2
    ;;
  -h | --help)
    show_usage
    exit 0
    ;;
  *)
    echo "Nieznana opcja: $1"
    show_usage
    exit 1
    ;;
  esac
done

TMP_DIR=$(mktemp -d)
echo "Utworzono tymczasowy katalog: $TMP_DIR"

mkdir -p "$TMP_DIR/html"
if [ -n "$CONTENT_FILE" ] && [ -f "$CONTENT_FILE" ]; then
  cp "$CONTENT_FILE" "$TMP_DIR/html/index.html"
  echo "Skopiowano zawartość z pliku: $CONTENT_FILE"
else
  echo "$CONTENT" >"$TMP_DIR/html/index.html"
  echo "Utworzono index.html z podaną zawartością"
fi

cat >"$TMP_DIR/Dockerfile" <<EOF
FROM nginx:alpine
COPY html /usr/share/nginx/html
EOF
echo "Utworzono Dockerfile"

echo "Budowanie obrazu Dockera..."
docker build -t nginx-custom "$TMP_DIR"

if docker ps -a | grep -q "$CONTAINER_NAME"; then
  echo "Zatrzymywanie i usuwanie istniejącego kontenera: $CONTAINER_NAME"
  docker stop "$CONTAINER_NAME" >/dev/null
  docker rm "$CONTAINER_NAME" >/dev/null
fi

echo "Uruchamianie kontenera Nginx na porcie $PORT..."
docker run -d --name "$CONTAINER_NAME" -p "$PORT:80" nginx-custom
echo "Nginx jest teraz dostępny pod adresem http://localhost:$PORT"

echo "Czyszczenie tymczasowych plików..."
rm -rf "$TMP_DIR"
