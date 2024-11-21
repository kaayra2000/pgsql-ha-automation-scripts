#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/haproxy_setup.sh
source $SCRIPT_DIR/../argument_parser.sh # argument_parser.sh dosyasındaki fonksiyonları kullanmak için
source $SCRIPT_DIR/../general_functions.sh
check_and_parse_arguments $ARGUMENT_CFG_FILE
ha_proxy_kur
ha_proxy_konfigure_et $NODE1_IP $NODE2_IP $HAPROXY_BIND_PORT $POSTGRES_BIND_PORT $PGSQL_PORT $HAPROXY_PORT
enable_haproxy
