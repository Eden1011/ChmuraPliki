#!/bin/bash

show_help() {
  echo "Użycie: $0 [opcja]"
  echo "Opcje:"
  echo "  encrypt VOLUME_NAME PASSWORD - Zaszyfruj wolumin"
  echo "  decrypt ARCHIVE_NAME PASSWORD - Odszyfruj archiwum do woluminu"
  echo "  help - Wyświetl tę pomoc"
  exit 0
}
if [ $# -lt 1 ]; then
  show_help
fi
if [ "$1" = "help" ]; then
  show_help
fi
encrypt_volume() {
  if [ $# -ne 2 ]; then
    echo "Błąd: Nieprawidłowa liczba argumentów dla encrypt"
    echo "Użycie: $0 encrypt VOLUME_NAME PASSWORD"
    exit 1
  fi

  VOLUME_NAME=$1
  PASSWORD=$2
  ARCHIVE_NAME="${VOLUME_NAME}_encrypted.tar.gz.gpg"
  if ! docker volume inspect "$VOLUME_NAME" &>/dev/null; then
    echo "Błąd: Wolumin $VOLUME_NAME nie istnieje"
    exit 1
  fi

  echo "Rozpoczynam szyfrowanie woluminu $VOLUME_NAME..."

  docker run --rm -v "$VOLUME_NAME":/data -v "$(pwd)":/backup alpine sh -c "
    apk add --no-cache gnupg && 
    cd /data && 
    tar czf /backup/temp_archive.tar.gz . && 
    cd /backup && 
    echo $PASSWORD | gpg --batch --yes --passphrase-fd 0 -c -o $ARCHIVE_NAME temp_archive.tar.gz && 
    rm temp_archive.tar.gz"

  if [ $? -eq 0 ]; then
    echo "Wolumin $VOLUME_NAME został zaszyfrowany i zapisany jako $ARCHIVE_NAME"
  else
    echo "Wystąpił błąd podczas szyfrowania woluminu"
    exit 1
  fi
}

decrypt_volume() {
  if [ $# -ne 2 ]; then
    echo "Błąd: Nieprawidłowa liczba argumentów dla decrypt"
    echo "Użycie: $0 decrypt ARCHIVE_NAME PASSWORD"
    exit 1
  fi

  ARCHIVE_NAME=$1
  PASSWORD=$2

  VOLUME_NAME=$(echo "$ARCHIVE_NAME" | sed 's/_encrypted\.tar\.gz\.gpg$//')

  if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "Błąd: Plik $ARCHIVE_NAME nie istnieje"
    exit 1
  fi

  echo "Tworzenie woluminu $VOLUME_NAME (jeśli nie istnieje)..."
  docker volume create "$VOLUME_NAME" &>/dev/null

  echo "Rozpoczynam odszyfrowywanie archiwum $ARCHIVE_NAME do woluminu $VOLUME_NAME..."

  docker run --rm -v "$VOLUME_NAME":/data -v "$(pwd)":/backup alpine sh -c "
    apk add --no-cache gnupg && 
    cd /backup && 
    echo $PASSWORD | gpg --batch --yes --passphrase-fd 0 -d -o temp_archive.tar.gz $ARCHIVE_NAME && 
    tar xzf temp_archive.tar.gz -C /data && 
    rm temp_archive.tar.gz"

  if [ $? -eq 0 ]; then
    echo "Archiwum $ARCHIVE_NAME zostało odszyfrowane i rozpakowane do woluminu $VOLUME_NAME"
  else
    echo "Wystąpił błąd podczas odszyfrowywania archiwum"
    exit 1
  fi
}

case "$1" in
encrypt)
  encrypt_volume "$2" "$3"
  ;;
decrypt)
  decrypt_volume "$2" "$3"
  ;;
*)
  echo "Nieznana opcja: $1"
  show_help
  ;;
esac

exit 0
