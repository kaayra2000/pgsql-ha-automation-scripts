#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../default_variables.sh
source $SCRIPT_DIR/../general_functions.sh
# Argümanları parse et
parse_arguments() {
    # Argüman anahtarları
    declare -A ARG_KEYS=(
        ["INTERFACE_KEY"]="--interface"
        ["SQL_VIRTUAL_IP_KEY"]="--sql-virtual-ip"
        ["DNS_VIRTUAL_IP_KEY"]="--dns-virtual-ip"
        ["PRIORITY_KEY"]="--priority"
        ["STATE_KEY"]="--state"
        ["SQL_CONTAINER_KEY"]="--sql-container"
        ["DNS_CONTAINER_KEY"]="--dns-container"
    )

    # Argüman tanımlamaları
    declare -A ARG_DESCRIPTIONS=(
        ["${ARG_KEYS[INTERFACE_KEY]}"]="Ağ arayüzü (varsayılan: $DEFAULT_INTERFACE)"
        ["${ARG_KEYS[SQL_VIRTUAL_IP_KEY]}"]="SQL sanal IP adresi (varsayılan: $DEFAULT_SQL_VIRTUAL_IP)"
        ["${ARG_KEYS[DNS_VIRTUAL_IP_KEY]}"]="DNS sanal IP adresi (varsayılan: $DEFAULT_DNS_VIRTUAL_IP)"
        ["${ARG_KEYS[PRIORITY_KEY]}"]="Öncelik değeri (varsayılan: $DEFAULT_PRIORITY)"
        ["${ARG_KEYS[STATE_KEY]}"]="Durum (MASTER/BACKUP) (varsayılan: $DEFAULT_STATE)"
        ["${ARG_KEYS[SQL_CONTAINER_KEY]}"]="SQL konteyner adı (varsayılan: $DEFAULT_SQL_CONTAINER)"
        ["${ARG_KEYS[DNS_CONTAINER_KEY]}"]="DNS konteyner adı (varsayılan: $DEFAULT_DNS_CONTAINER)"
    )
    # Değişkenleri diziye aktar
    declare -A config=(
        ["INTERFACE"]="$DEFAULT_INTERFACE"
        ["SQL_VIRTUAL_IP"]="$DEFAULT_SQL_VIRTUAL_IP"
        ["DNS_VIRTUAL_IP"]="$DEFAULT_DNS_VIRTUAL_IP"
        ["PRIORITY"]="$DEFAULT_PRIORITY"
        ["STATE"]="$DEFAULT_STATE"
        ["SQL_CONTAINER"]="$DEFAULT_SQL_CONTAINER"
        ["DNS_CONTAINER"]="$DEFAULT_DNS_CONTAINER"
    )

    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help "Keepalived" ARG_DESCRIPTIONS
            exit 0
            ;;
        ${ARG_KEYS[INTERFACE_KEY]})
            config["INTERFACE"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[SQL_VIRTUAL_IP_KEY]})
            config["SQL_VIRTUAL_IP"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[DNS_VIRTUAL_IP_KEY]})
            config["DNS_VIRTUAL_IP"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[PRIORITY_KEY]})
            config["PRIORITY"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[STATE_KEY]})
            if [[ "$2" != "MASTER" && "$2" != "BACKUP" ]]; then
                echo "Hata: State sadece MASTER veya BACKUP olabilir."
                exit 1
            fi
            config["STATE"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[SQL_CONTAINER_KEY]})
            config["SQL_CONTAINER"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[DNS_CONTAINER_KEY]})
            config["DNS_CONTAINER"]="$2"
            shift 2
            ;;
        *)
            echo "Hata: Bilinmeyen argüman '$1'"
            show_help
            exit 1
            ;;
        esac
    done

    # Değişkenleri export et
    for key in "${!config[@]}"; do
        export "$key"="${config[$key]}"
    done
}
