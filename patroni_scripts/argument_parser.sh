#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../default_variables.sh
source $SCRIPT_DIR/../general_functions.sh

# Argümanları parse et
parse_arguments_patroni() {
    # Argüman anahtarları
    declare -A ARG_KEYS=(
        ["NODE_NAME"]="--node-name"
        ["NODE1_IP"]="--node1-ip"
        ["NODE2_IP"]="--node2-ip"
        ["ETCD_IP"]="--etcd-ip"
        ["ETCD_PORT"]="--etcd-port"
        ["HAPROXY_PORT"]="--haproxy-port"
        ["PGSQL_PORT"]="--pgsql-port"
        ["REPLIKATOR_KULLANICI_ADI"]="--replicator-username"
        ["REPLICATOR_SIFRESI"]="--replicator-password"
        ["POSTGRES_SIFRESI"]="--postgres-password"
        ["IS_NODE_1"]="--is-node1"
    )

    # Varsayılan değerleri tanımla
    declare -A defaults=(
        ["NODE_NAME"]="$DEFAULT_NODE_NAME"
        ["NODE1_IP"]="$DEFAULT_NODE1_IP"
        ["NODE2_IP"]="$DEFAULT_NODE2_IP"
        ["ETCD_IP"]="$DEFAULT_ETCD_IP"
        ["ETCD_PORT"]="$DEFAULT_ETCD_PORT"
        ["HAPROXY_PORT"]="$DEFAULT_HAPROXY_PORT"
        ["PGSQL_PORT"]="$DEFAULT_PGSQL_PORT"
        ["REPLIKATOR_KULLANICI_ADI"]="$DEFAULT_REPLIKATOR_KULLANICI_ADI"
        ["REPLICATOR_SIFRESI"]="$DEFAULT_REPLICATOR_SIFRESI"
        ["POSTGRES_SIFRESI"]="$DEFAULT_POSTGRES_SIFRESI"
        ["IS_NODE_1"]="$DEFAULT_IS_NODE_1"
    )

    # Argüman tanımlamaları
    declare -A ARG_DESCRIPTIONS=(
        ["${ARG_KEYS[NODE_NAME]}"]="Node adı (varsayılan: ${defaults[NODE_NAME]})"
        ["${ARG_KEYS[NODE1_IP]}"]="Birinci node IP adresi (varsayılan: ${defaults[NODE1_IP]})"
        ["${ARG_KEYS[NODE2_IP]}"]="İkinci node IP adresi (varsayılan: ${defaults[NODE2_IP]})"
        ["${ARG_KEYS[ETCD_IP]}"]="Etcd IP adresi (varsayılan: ${defaults[ETCD_IP]})"
        ["${ARG_KEYS[ETCD_PORT]}"]="Etcd portu (varsayılan: ${defaults[ETCD_PORT]})"
        ["${ARG_KEYS[HAPROXY_PORT]}"]="HAProxy kontrol portu (varsayılan: ${defaults[HAPROXY_PORT]})"
        ["${ARG_KEYS[PGSQL_PORT]}"]="PostgreSQL portu (varsayılan: ${defaults[PGSQL_PORT]})"
        ["${ARG_KEYS[REPLIKATOR_KULLANICI_ADI]}"]="Replikator kullanıcısı (varsayılan: ${defaults[REPLIKATOR_KULLANICI_ADI]})"
        ["${ARG_KEYS[REPLICATOR_SIFRESI]}"]="Replikator şifresi (varsayılan: ${defaults[REPLICATOR_SIFRESI]})"
        ["${ARG_KEYS[POSTGRES_SIFRESI]}"]="Postgres şifresi (varsayılan: ${defaults[POSTGRES_SIFRESI]})"
        ["${ARG_KEYS[IS_NODE_1]}"]="Mevcut node'un node1 olup olmadığını belirtiyor (varsayılan: ${defaults[IS_NODE_1]})"
    )

    # Varsayılan değerleri ayarla
    declare -A config=(
        ["NODE_NAME"]="${defaults[NODE_NAME]}"
        ["NODE1_IP"]="${defaults[NODE1_IP]}"
        ["NODE2_IP"]="${defaults[NODE2_IP]}"
        ["ETCD_IP"]="${defaults[ETCD_IP]}"
        ["ETCD_PORT"]="${defaults[ETCD_PORT]}"
        ["HAPROXY_PORT"]="${defaults[HAPROXY_PORT]}"
        ["PGSQL_PORT"]="${defaults[PGSQL_PORT]}"
        ["REPLIKATOR_KULLANICI_ADI"]="${defaults[REPLIKATOR_KULLANICI_ADI]}"
        ["REPLICATOR_SIFRESI"]="${defaults[REPLICATOR_SIFRESI]}"
        ["POSTGRES_SIFRESI"]="${defaults[POSTGRES_SIFRESI]}"
        ["IS_NODE_1"]="${defaults[IS_NODE_1]}"
    )

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help "Patroni" ARG_DESCRIPTIONS
                return $HELP_CODE
                ;;
            ${ARG_KEYS[NODE_NAME]})
                config["NODE_NAME"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[NODE1_IP]})
                config["NODE1_IP"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[NODE2_IP]})
                config["NODE2_IP"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[ETCD_IP]})
                config["ETCD_IP"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[ETCD_PORT]})
                config["ETCD_PORT"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[HAPROXY_PORT]})
                config["HAPROXY_PORT"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[PGSQL_PORT]})
                config["PGSQL_PORT"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[REPLIKATOR_KULLANICI_ADI]})
                config["REPLIKATOR_KULLANICI_ADI"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[REPLICATOR_SIFRESI]})
                config["REPLICATOR_SIFRESI"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[POSTGRES_SIFRESI]})
                config["POSTGRES_SIFRESI"]="$2"
                shift 2
                ;;
            ${ARG_KEYS[IS_NODE_1]})
                config["IS_NODE_1"]="$2"
                shift 2
                ;;
            *)
                echo "Uyarı: Bilinmeyen argüman '$1' atlanıyor (belki docker argümanıdır)"
                # Eğer bir sonraki parametre '-' ile başlamıyorsa onu da atla
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