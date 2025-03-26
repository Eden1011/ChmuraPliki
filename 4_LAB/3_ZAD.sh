#!/bin/bash

echo "Sprawdzanie zużycia przestrzeni dyskowej woluminów Docker"
echo "--------------------------------------------------------"
VOLUMES=$(docker volume ls -q)
if [ -z "$VOLUMES" ]; then
  echo "Nie znaleziono żadnych woluminów Docker."
  exit 0
fi
echo "Wolumin               | Rozmiar  | Użyte    | Dostępne | Użycie %"
echo "----------------------|----------|----------|----------|--------"
for VOLUME in $VOLUMES; do
  USAGE=$(docker run --rm -v $VOLUME:/vol alpine df -h /vol | awk 'NR==2 {print $2 " " $3 " " $4 " " $5}')
  SIZE=$(echo $USAGE | awk '{print $1}')
  USED=$(echo $USAGE | awk '{print $2}')
  AVAIL=$(echo $USAGE | awk '{print $3}')
  PERCENT=$(echo $USAGE | awk '{print $4}')
  printf "%-20s | %-8s | %-8s | %-8s | %-8s\n" "$VOLUME" "$SIZE" "$USED" "$AVAIL" "$PERCENT"
done
echo "--------------------------------------------------------"
echo "Zakończono sprawdzanie zużycia przestrzeni woluminów Docker."
