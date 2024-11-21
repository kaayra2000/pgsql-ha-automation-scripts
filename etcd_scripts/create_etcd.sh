#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/etcd_setup.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh
ETCD_CONFIG_DIR="/etc/etcd"
ETCD_CONFIG_FILE="$ETCD_CONFIG_DIR/etcd.conf.yml"
ETCD_USER="etcd"
check_and_parse_arguments $ARGUMENT_CFG_FILE "$@"
# Sayısal değer kontrolü
# Dizin kontrolü
if ! check_directory "$DATA_DIR"; then
    exit 1
fi

if ! check_directory "$ETCD_CONFIG_DIR"; then
    exit 1
fi

# Dizinler oluşturulduktan sonra kullanıcı kontrolü
if ! check_user_exists "$ETCD_USER"; then
    echo "Hata: Kullanıcı $ETCD_USER mevcut değil. Devam edilemiyor."
    exit 1
fi

# Kullanıcı varsa, dizinlerin sahipliğini ve izinlerini ayarla
if ! set_permissions "$ETCD_USER" "$DATA_DIR" "700"; then
    echo "Hata: $DATA_DIR için izinler ayarlanamadı."
    exit 1
fi

if ! set_permissions "$ETCD_USER" "$ETCD_CONFIG_DIR" "700"; then
    echo "Hata: $ETCD_CONFIG_DIR için izinler ayarlanamadı."
    exit 1
fi

# ETCD kurulum ve konfigürasyon
etcd_kur
etcd_konfigure_et "$ETCD_CONFIG_FILE"
if ! set_permissions "$ETCD_USER" "$ETCD_CONFIG_FILE" "600"; then
    echo "Hata: $ETCD_CONFIG_FILE için izinler ayarlanamadı."
    exit 1
fi

if ! update_daemon_args "$ETCD_CONFIG_FILE"; then
    echo "Hata: etcd daemon argümanları güncellenemedi."
    exit 1
fi

if ! etcd_etkinlestir $ETCD_CLIENT_PORT; then
    echo "Hata: etcd servisi başlatılamadı."
    exit 1
fi