#!/bin/bash

echo "Uruchamianie kontenerów..."
docker-compose up -d

echo "Czekanie na uruchomienie serwisów..."
sleep 10

echo "Sprawdzanie połączeń sieciowych:"

echo -e "\n1. Test z frontend do backend:"
docker exec frontend curl -s backend:5000
if [ $? -eq 0 ]; then
  echo "OK - Frontend może połączyć się z Backend"
else
  echo "BŁĄD - Frontend nie może połączyć się z Backend"
fi

echo -e "\n2. Test z frontend do database (powinien się nie powieść):"
docker exec frontend ping -c 2 database
if [ $? -eq 0 ]; then
  echo "BŁĄD - Frontend nie powinien mieć dostępu do Database"
else
  echo "OK - Frontend nie ma dostępu do Database"
fi

echo -e "\n3. Test z backend do database:"
docker exec backend curl -s http://localhost:5000/check-database
if [ $? -eq 0 ]; then
  echo "OK - Backend może połączyć się z Database"
else
  echo "BŁĄD - Backend nie może połączyć się z Database"
fi

echo -e "\n4. Informacje o sieci z punktu widzenia backend:"
docker exec backend curl -s http://localhost:5000/network-info

echo -e "\n5. Sprawdzanie dostępności aplikacji przez przeglądarkę:"
curl -s http://localhost:8080 >/dev/null
if [ $? -eq 0 ]; then
  echo "OK - Frontend jest dostępny na http://localhost:8080"
else
  echo "BŁĄD - Frontend nie jest dostępny na http://localhost:8080"
fi

echo -e "\n6. Sprawdzanie dostępności backend przez API proxy:"
curl -s http://localhost:8080/api >/dev/null
if [ $? -eq 0 ]; then
  echo "OK - Backend API jest dostępne przez proxy na http://localhost:8080/api"
else
  echo "BŁĄD - Backend API nie jest dostępne przez proxy na http://localhost:8080/api"
fi

echo -e "\nLogi frontend:"
docker logs frontend | tail -5

echo -e "\nLogi backend:"
docker logs backend | tail -5

echo -e "\nLogi database:"
docker logs database | tail -5

echo -e "\nCzy chcesz zatrzymać kontenery? (t/n)"
read answer
if [ "$answer" = "t" ]; then
  docker-compose down
  echo "Kontenery zatrzymane."
fi
