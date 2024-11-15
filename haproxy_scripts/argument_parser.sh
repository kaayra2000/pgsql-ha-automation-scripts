#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../default_variables.sh
source $SCRIPT_DIR/../general_functions.sh

# Argümanları parse et
parse_arguments_haproxy() {
    # Argüman anahtarları
    declare -A ARG_KEYS=(
        ["NODE1_IP"]="--node1-ip"
        ["NODE2_IP"]="--node2-ip"
        ["HAPROXY_BIND_PORT"]="--haproxy-bind-port"
        ["PGSQL_PORT"]="--pgsql-port"
        ["HAPROXY_PORT"]="--haproxy-port"
        ["POSTGRES_BIND_PORT"]="--postgres-bind-port"
    )

    # Argüman tanımlamaları
    declare -A ARG_DESCRIPTIONS=(
        ["${ARG_KEYS[NODE1_IP]}"]="Birinci node IP adresi (varsayılan: $DEFAULT_NODE1_IP)"
        ["${ARG_KEYS[NODE2_IP]}"]="İkinci node IP adresi (varsayılan: $DEFAULT_NODE2_IP)"
        ["${ARG_KEYS[HAPROXY_BIND_PORT]}"]="HAProxy bind portu (varsayılan: $DEFAULT_HAPROXY_BIND_PORT)"
        ["${ARG_KEYS[PGSQL_PORT]}"]="PostgreSQL portu (varsayılan: $DEFAULT_PGSQL_PORT)"
        ["${ARG_KEYS[HAPROXY_PORT]}"]="HAProxy kontrol portu (varsayılan: $DEFAULT_HAPROXY_PORT)"
        ["${ARG_KEYS[POSTGRES_BIND_PORT]}"]="PostgreSQL bind portu (varsayılan: $DEFAULT_POSTGRES_BIND_PORT)"
    )

    # Varsayılan değerleri ayarla
    declare -A config=(
        ["NODE1_IP"]="$DEFAULT_NODE1_IP"
        ["NODE2_IP"]="$DEFAULT_NODE2_IP"
        ["HAPROXY_BIND_PORT"]="$DEFAULT_HAPROXY_BIND_PORT"
        ["PGSQL_PORT"]="$DEFAULT_PGSQL_PORT"
        ["HAPROXY_PORT"]="$DEFAULT_HAPROXY_PORT"
        ["POSTGRES_BIND_PORT"]="$DEFAULT_POSTGRES_BIND_PORT"
    )

    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help "HAProxy" ARG_DESCRIPTIONS
            return $HELP_CODE
            ;;
        ${ARG_KEYS[NODE1_IP]})
            config["NODE1_IP"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[NODE2_IP]})
            config["NODE2_IP"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[HAPROXY_BIND_PORT]})
            config["HAPROXY_BIND_PORT"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[PGSQL_PORT]})
            config["PGSQL_PORT"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[HAPROXY_PORT]})
            config["HAPROXY_PORT"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[POSTGRES_BIND_PORT]})
            config["POSTGRES_BIND_PORT"]="$2"
            shift 2
            ;;
        *)
            echo "Uyarı: Bilinmeyen argüman '$1' atlanıyor (belki docker argümanıdır)"
            # Eğer bir sonraki parametre - ile başlamıyorsa onu da atla
            if [[ $2 != -* ]] && [[ -n $2 ]]; then
                shift 2
            else
                shift 1
            fi
            ;;
        esac
    done

    # Değişkenleri export et
    for key in "${!config[@]}"; do
        export "$key"="${config[$key]}"
    done
}