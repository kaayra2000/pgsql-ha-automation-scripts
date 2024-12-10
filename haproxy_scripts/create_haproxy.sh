#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/haproxy_setup.sh
source $SCRIPT_DIR/../argument_parser.sh # argument_parser.sh dosyasındaki fonksiyonları kullanmak için
source $SCRIPT_DIR/../general_functions.sh
parse_and_read_arguments "$@"
ha_proxy_kur
ha_proxy_konfigure_et
update_haproxy_init_script
start_haproxy
