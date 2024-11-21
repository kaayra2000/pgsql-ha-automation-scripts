#!/bin/bash
# Script'in bulunduğu dizini alma
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/default_variables.sh"
source "$ROOT_DIR/general_functions.sh"
ARGUMENT_CFG_FILE="$ROOT_DIR/arguments.cfg"

# Argümanları işleyen ana fonksiyon
parse_all_arguments() {
    # Argümanları bir dizide tanımla
    declare -a ARGUMENTS=(
        # Anahtar               Komut Satırı Argümanı        Varsayılan Değer                   Yardım Açıklaması
        # HAProxy Argümanları
        "NODE1_IP"              "--node1-ip"                "$DEFAULT_NODE1_IP"                "1. Düğümün IP adresi"
        "NODE2_IP"              "--node2-ip"                "$DEFAULT_NODE2_IP"                "2. Düğümün IP adresi"
        "HAPROXY_BIND_PORT"     "--haproxy-bind-port"       "$DEFAULT_HAPROXY_BIND_PORT"       "HAProxy bağlantı portu"
        "PGSQL_PORT"            "--pgsql-port"              "$DEFAULT_PGSQL_PORT"              "PostgreSQL portu"
        "HAPROXY_PORT"          "--haproxy-port"            "$DEFAULT_HAPROXY_PORT"            "HAProxy portu"
        "POSTGRES_BIND_PORT"    "--postgres-bind-port"      "$DEFAULT_POSTGRES_BIND_PORT"      "PostgreSQL bağlantı portu"

        # Keepalived Argümanları
        "INTERFACE"             "--interface"               "$DEFAULT_INTERFACE"               "Ağ arayüzü"
        "SQL_VIRTUAL_IP"        "--sql-virtual-ip"          "$DEFAULT_SQL_VIRTUAL_IP"          "SQL sanal IP adresi"
        "DNS_VIRTUAL_IP"        "--dns-virtual-ip"          "$DEFAULT_DNS_VIRTUAL_IP"          "DNS sanal IP adresi"
        "PRIORITY"              "--priority"                "$DEFAULT_PRIORITY"                "Keepalived önceliği"
        "STATE"                 "--state"                   "$DEFAULT_STATE"                   "Başlangıç durumu (MASTER/BACKUP)"
        "SQL_CONTAINER"         "--sql-container"           "$DEFAULT_SQL_CONTAINER"           "SQL konteyner adı"
        "DNS_CONTAINER"         "--dns-container"           "$DEFAULT_DNS_CONTAINER"           "DNS konteyner adı"

        # Patroni Argümanları
        "NODE_NAME"             "--node-name"               "$DEFAULT_NODE_NAME"               "Düğüm adı"
        "ETCD_IP"               "--etcd-ip"                 "$DEFAULT_ETCD_IP"                 "ETCD IP adresi"
        "REPLIKATOR_KULLANICI_ADI" "--replicator-username"  "$DEFAULT_REPLIKATOR_KULLANICI_ADI" "Replikasyon kullanıcı adı"
        "REPLICATOR_SIFRESI"    "--replicator-password"     "$DEFAULT_REPLICATOR_SIFRESI"      "Replikasyon şifresi"
        "POSTGRES_SIFRESI"      "--postgres-password"       "$DEFAULT_POSTGRES_SIFRESI"        "Postgres şifresi"
        "IS_NODE_1"             "--is-node1"                "$DEFAULT_IS_NODE_1"               "Bu düğüm 1. düğüm mü?"

        # ETCD Argümanları
        "ETCD_CLIENT_PORT"      "--client-port"             "$DEFAULT_ETCD_CLIENT_PORT"        "ETCD istemci portu"
        "ETCD_PEER_PORT"        "--peer-port"               "$DEFAULT_ETCD_PEER_PORT"          "ETCD eşler arası port"
        "CLUSTER_TOKEN"         "--cluster-token"           "$DEFAULT_CLUSTER_TOKEN"           "Küme belirteci"
        "CLUSTER_STATE"         "--cluster-state"           "$DEFAULT_CLUSTER_STATE"           "Küme durumu (new/existing)"
        "ETCD_NAME"             "--etcd-name"               "$DEFAULT_ETCD_NAME"               "ETCD düğüm adı"
        "ELECTION_TIMEOUT"      "--election-timeout"        "$DEFAULT_ELECTION_TIMEOUT"        "Seçim zaman aşımı"
        "HEARTBEAT_INTERVAL"    "--heartbeat-interval"      "$DEFAULT_HEARTBEAT_INTERVAL"      "Nabız aralığı"
        "DATA_DIR"              "--data-dir"                "$DEFAULT_DATA_DIR"                "Veri dizini"
    )

    # Yapılandırma için ilişkisel dizi oluştur ve varsayılan değerlerle başlat
    declare -A config
    local arg_count=${#ARGUMENTS[@]}
    for ((i=0; i<$arg_count; i+=4)); do
        local key="${ARGUMENTS[i]}"
        local default_value="${ARGUMENTS[i+2]}"
        config["$key"]="$default_value"
    done

    # Argümanları işle
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_argument_help "$0" ARGUMENTS
                exit 0
                ;;
            *)
                local found=false
                for ((i=0; i<$arg_count; i+=4)); do
                    local key="${ARGUMENTS[i]}"
                    local flag="${ARGUMENTS[i+1]}"
                    if [ "$1" == "$flag" ]; then
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

    # Değişkenleri yapılandırma dosyasına yaz
    > "$ARGUMENT_CFG_FILE"  # Dosyayı temizle veya oluştur
    for key in "${!config[@]}"; do
        echo "$key=${config[$key]}" >> "$ARGUMENT_CFG_FILE"
    done
}