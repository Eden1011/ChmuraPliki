#!/bin/bash
docker volume create nginx_data
docker run --rm -v nginx_data:/data alpine sh -c "echo '<html><body><h1>Moja niestandardowa strona Nginx</h1><p>Ta strona została zmodyfikowana za pomocą woluminu Docker.</p></body></html>' > /data/index.html"
docker run -d --name moj_nginx -p 80:80 -v nginx_data:/usr/share/nginx/html nginx
echo "Kontener Nginx został uruchomiony. Dostęp do strony: http://localhost"
echo "Aby zatrzymać kontener, użyj: docker stop moj_nginx"
echo "Aby usunąć kontener, użyj: docker rm moj_nginx"
