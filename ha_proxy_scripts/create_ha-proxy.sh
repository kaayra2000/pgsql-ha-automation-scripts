#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/ha-proxy_setup.sh
source $SCRIPT_DIR/../varsayilan_degiskenler.sh # varsayilan_degiskenler.sh dosyasındaki değişkenleri kullanmak için
source $SCRIPT_DIR/argument_parser.sh           # argument_parser.sh dosyasındaki fonksiyonları kullanmak için
source $SCRIPT_DIR/validator.sh                 # validator.sh dosyasındaki fonksiyonları kullanmak için

parse_arguments "$@"
validate_ip $NODE1_IP
validate_ip $NODE2_IP
validate_ip $ETCD_IP
validate_port $HAPROXY_BIND_PORT
validate_port $PGSQL_PORT
validate_port $HAPROXY_PORT
ha_proxy_kur
ha_proxy_konfigure_et $NODE1_IP $NODE2_IP $ETCD_IP $HAPROXY_BIND_PORT $PGSQL_PORT $HAPROXY_PORT
