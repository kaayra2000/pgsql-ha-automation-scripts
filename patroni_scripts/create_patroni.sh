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

create_and_configure_neccessary_patroni_files

patroni_bootstrap_dosyasi_olustur

setup_patroni_init_script

patroni_yml_konfigure_et

patroni_etkinlestir