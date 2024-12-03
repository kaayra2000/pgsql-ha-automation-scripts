#!/bin/bash

<<COMMENT
    Buradaki değişkenler arguments.cfg dosyasından okunacak.
COMMENT

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/patroni_setup.sh
source $SCRIPT_DIR/../argument_parser.sh # argument_parser.sh dosyasındaki fonksiyonları kullanmak için
source $SCRIPT_DIR/../general_functions.sh

parse_and_read_arguments "$@"


if ! check_and_create_directory "$POSTGRES_DATA_DIR"; then
    exit 1
fi 

if ! check_user_exists "$POSTGRES_USER"; then
    echo "Hata: Kullanıcı postgres mevcut değil. Devam edilemiyor."
    exit 1
fi

sudo chown -R $POSTGRES_USER:$POSTGRES_USER $POSTGRES_DATA_ROOT_DIR
check_success "Dizin sahipliği değiştirilirken bir hata oluştu."

sudo chmod -R 700 $POSTGRES_DATA_ROOT_DIR
check_success "Dizin izinleri değiştirilirken bir hata oluştu."

patroni_bootstrap_dosyasi_olustur

patroni_yml_konfigure_et

patroni_etkinlestir