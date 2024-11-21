#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/patroni_setup.sh
source $SCRIPT_DIR/argument_parser.sh # argument_parser.sh dosyasındaki fonksiyonları kullanmak için
source $SCRIPT_DIR/../general_functions.sh

DATA_DIR="/data"
PATRONI_DIR="$DATA_DIR/patroni"
POSTGRES_USER="postgres"

parse_arguments_patroni "$@"

validate_ip $NODE1_IP
validate_ip $NODE2_IP
validate_ip $ETCD_IP

validate_port $ETCD_PORT
validate_port $HAPROXY_PORT
validate_port $PGSQL_PORT

if ! check_directory "$PATRONI_DIR"; then
    exit 1
fi 

if ! check_user_exists "$POSTGRES_USER"; then
    echo "Hata: Kullanıcı postgres mevcut değil. Devam edilemiyor."
    exit 1
fi

sudo chown -R $POSTGRES_USER:$POSTGRES_USER $DATA_DIR
check_success "Dizin sahipliği değiştirilirken bir hata oluştu."

sudo chmod -R 700 $PATRONI_DIR
check_success "Dizin izinleri değiştirilirken bir hata oluştu."

patroni_yml_konfigure_et $NODE_NAME $NODE1_IP $NODE2_IP $ETCD_IP $ETCD_PORT $HAPROXY_PORT $PGSQL_PORT $REPLIKATOR_KULLANICI_ADI $REPLICATOR_SIFRESI $POSTGRES_SIFRESI