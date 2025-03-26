#!/bin/bash
docker volume create nodejs_data
docker volume create all_volumes
docker run --rm -v nodejs_data:/data alpine sh -c "mkdir -p /data && echo 'console.log(\"Hello from Node.js\");' > /data/app.js"
docker run -d --name moj_nodejs -v nodejs_data:/app node:alpine tail -f /dev/null
if ! docker volume inspect nginx_data >/dev/null 2>&1; then
  echo "Wolumin nginx_data nie istnieje. Tworzenie..."
  docker volume create nginx_data
  docker run --rm -v nginx_data:/data alpine sh -c "echo '<html><body><h1>Przykładowa strona Nginx</h1></body></html>' > /data/index.html"
fi
docker run --rm -v nginx_data:/source -v all_volumes:/destination alpine sh -c "mkdir -p /destination/nginx && cp -r /source/* /destination/nginx/"
docker run --rm -v nodejs_data:/source -v all_volumes:/destination alpine sh -c "mkdir -p /destination/nodejs && cp -r /source/* /destination/nodejs/"
echo "Zawartość woluminu all_volumes:"
docker run --rm -v all_volumes:/data alpine sh -c "ls -la /data"
docker run --rm -v all_volumes:/data alpine sh -c "ls -la /data/nginx"
docker run --rm -v all_volumes:/data alpine sh -c "ls -la /data/nodejs"
echo "Proces zakończony. Utworzono i połączono woluminy."
echo "Aby zatrzymać kontener Node.js, użyj: docker stop moj_nodejs"
echo "Aby usunąć kontener, użyj: docker rm moj_nodejs"
