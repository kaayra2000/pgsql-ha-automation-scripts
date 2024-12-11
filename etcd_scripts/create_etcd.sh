#!/bin/bash

<<COMMENT
    Buradaki değişkenler arguments.cfg dosyasından okunacak.
COMMENT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/etcd_setup.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh

parse_and_read_arguments "$@"

if ! create_and_configure_neccessary_etcd_files; then
    echo "Hata: gerekli dosyalar oluşturulamadı."
    exit 1
fi

# ETCD kurulum ve konfigürasyon
etcd_kur

if ! etcd_konfigure_et "$ETCD_CONFIG_FILE"; then
    echo "Hata: $ETCD_CONFIG_FILE için izinler ayarlanamadı."
    exit 1
fi

if ! update_etcd_init_script "$ETCD_CONFIG_FILE"; then
    echo "Hata: etcd daemon argümanları güncellenemedi."
    exit 1
fi

if ! start_etcd $ETCD_CLIENT_PORT; then
    echo "Hata: etcd servisi başlatılamadı."
    exit 1
fi