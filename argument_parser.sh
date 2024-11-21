#!/bin/bash
# Script'in bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/default_variables.sh"
source "$SCRIPT_DIR/general_functions.sh"
ARGUMENT_CFG_FILE="$SCRIPT_DIR/arguments.cfg"

# Argümanları işleyen genel fonksiyon
parse_all_arguments() {
    # Tüm argüman anahtarlarını ve varsayılan değerleri birleştirelim
    declare -A ARG_KEYS=(
        # HAProxy Argümanları
        ["NODE1_IP"]="--node1-ip"
        ["NODE2_IP"]="--node2-ip"
        ["HAPROXY_BIND_PORT"]="--haproxy-bind-port"
        ["PGSQL_PORT"]="--pgsql-port"
        ["HAPROXY_PORT"]="--haproxy-port"
        ["POSTGRES_BIND_PORT"]="--postgres-bind-port"

        # Keepalived Argümanları
        ["INTERFACE"]="--interface"
        ["SQL_VIRTUAL_IP"]="--sql-virtual-ip"
        ["DNS_VIRTUAL_IP"]="--dns-virtual-ip"
        ["PRIORITY"]="--priority"
        ["STATE"]="--state"
        ["SQL_CONTAINER"]="--sql-container"
        ["DNS_CONTAINER"]="--dns-container"

        # Patroni Argümanları
        ["NODE_NAME"]="--node-name"
        ["ETCD_IP"]="--etcd-ip"
        ["REPLIKATOR_KULLANICI_ADI"]="--replicator-username"
        ["REPLICATOR_SIFRESI"]="--replicator-password"
        ["POSTGRES_SIFRESI"]="--postgres-password"
        ["IS_NODE_1"]="--is-node1"

        # ETCD Argümanları
        ["ETCD_CLIENT_PORT"]="--client-port"
        ["ETCD_PEER_PORT"]="--peer-port"
        ["CLUSTER_TOKEN"]="--cluster-token"
        ["CLUSTER_STATE"]="--cluster-state"
        ["ETCD_NAME"]="--etcd-name"
        ["ELECTION_TIMEOUT"]="--election-timeout"
        ["HEARTBEAT_INTERVAL"]="--heartbeat-interval"
        ["DATA_DIR"]="--data-dir"
    )

    # Varsayılan değerleri ayarla
    declare -A config=(
        # HAProxy Varsayılanları
        ["NODE1_IP"]="$DEFAULT_NODE1_IP"
        ["NODE2_IP"]="$DEFAULT_NODE2_IP"
        ["HAPROXY_BIND_PORT"]="$DEFAULT_HAPROXY_BIND_PORT"
        ["PGSQL_PORT"]="$DEFAULT_PGSQL_PORT"
        ["HAPROXY_PORT"]="$DEFAULT_HAPROXY_PORT"
        ["POSTGRES_BIND_PORT"]="$DEFAULT_POSTGRES_BIND_PORT"

        # Keepalived Varsayılanları
        ["INTERFACE"]="$DEFAULT_INTERFACE"
        ["SQL_VIRTUAL_IP"]="$DEFAULT_SQL_VIRTUAL_IP"
        ["DNS_VIRTUAL_IP"]="$DEFAULT_DNS_VIRTUAL_IP"
        ["PRIORITY"]="$DEFAULT_PRIORITY"
        ["STATE"]="$DEFAULT_STATE"
        ["SQL_CONTAINER"]="$DEFAULT_SQL_CONTAINER"
        ["DNS_CONTAINER"]="$DEFAULT_DNS_CONTAINER"

        # Patroni Varsayılanları
        ["NODE_NAME"]="$DEFAULT_NODE_NAME"
        ["ETCD_IP"]="$DEFAULT_ETCD_IP"
        ["REPLIKATOR_KULLANICI_ADI"]="$DEFAULT_REPLIKATOR_KULLANICI_ADI"
        ["REPLICATOR_SIFRESI"]="$DEFAULT_REPLICATOR_SIFRESI"
        ["POSTGRES_SIFRESI"]="$DEFAULT_POSTGRES_SIFRESI"
        ["IS_NODE_1"]="$DEFAULT_IS_NODE_1"

        # ETCD Varsayılanları
        ["ETCD_CLIENT_PORT"]="$DEFAULT_ETCD_CLIENT_PORT"
        ["ETCD_PEER_PORT"]="$DEFAULT_ETCD_PEER_PORT"
        ["CLUSTER_TOKEN"]="$DEFAULT_CLUSTER_TOKEN"
        ["CLUSTER_STATE"]="$DEFAULT_CLUSTER_STATE"
        ["ETCD_NAME"]="$DEFAULT_ETCD_NAME"
        ["ELECTION_TIMEOUT"]="$DEFAULT_ELECTION_TIMEOUT"
        ["HEARTBEAT_INTERVAL"]="$DEFAULT_HEARTBEAT_INTERVAL"
        ["DATA_DIR"]="$DEFAULT_DATA_DIR"
    )

    # Argümanları parse et
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help  # Yardım mesajını gösteren fonksiyon (tanımlamalısınız)
                exit 0
                ;;
            *)
                local found=false
                for key in "${!ARG_KEYS[@]}"; do
                    if [ "$1" == "${ARG_KEYS[$key]}" ]; then
                        config["$key"]="$2"
                        shift 2
                        found=true
                        break
                    fi
                done
                if ! $found; then
                    echo "Uyarı: Bilinmeyen argüman '$1' atlanıyor"
                    shift 1
                fi
                ;;
        esac
    done

    # Değişkenleri dosyaya yaz
    > "$ARGUMENT_CFG_FILE"  # Dosyayı temizle veya oluştur
    for key in "${!config[@]}"; do
        echo "$key=${config[$key]}" >> "$ARGUMENT_CFG_FILE"
    done
}