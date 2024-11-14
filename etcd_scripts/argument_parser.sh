#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../default_variables.sh

# Argüman anahtarları
declare -A ARG_KEYS=(
    ["ETCD_IP"]="--etcd-ip"
    ["ETCD_CLIENT_PORT"]="--client-port"
    ["ETCD_PEER_PORT"]="--peer-port"
    ["CLUSTER_TOKEN"]="--cluster-token"
    ["CLUSTER_STATE"]="--cluster-state"
    ["ETCD_NAME"]="--etcd-name"
    ["ELECTION_TIMEOUT"]="--election-timeout"
    ["HEARTBEAT_INTERVAL"]="--heartbeat-interval"
    ["DATA_DIR"]="--data-dir"
)

# Argüman tanımlamaları
declare -A ARG_DESCRIPTIONS=(
    ["${ARG_KEYS[ETCD_IP]}"]="ETCD sunucusunun IP adresi (varsayılan: $DEFAULT_ETCD_IP)"
    ["${ARG_KEYS[ETCD_CLIENT_PORT]}"]="ETCD client port (varsayılan: $DEFAULT_ETCD_CLIENT_PORT)"
    ["${ARG_KEYS[ETCD_PEER_PORT]}"]="ETCD peer port (varsayılan: $DEFAULT_ETCD_PEER_PORT)"
    ["${ARG_KEYS[CLUSTER_TOKEN]}"]="Cluster token (varsayılan: $DEFAULT_CLUSTER_TOKEN)"
    ["${ARG_KEYS[CLUSTER_STATE]}"]="Cluster durumu (varsayılan: $DEFAULT_CLUSTER_STATE)"
    ["${ARG_KEYS[ETCD_NAME]}"]="ETCD node ismi (varsayılan: etcd1)"
    ["${ARG_KEYS[ELECTION_TIMEOUT]}"]="Seçim zaman aşımı ms (varsayılan: 5000)"
    ["${ARG_KEYS[HEARTBEAT_INTERVAL]}"]="Heartbeat aralığı ms (varsayılan: 1000)"
    ["${ARG_KEYS[DATA_DIR]}"]="ETCD veri dizini (varsayılan: /var/lib/etcd/default)"
)

# Yardım mesajını göster
show_help() {
    echo "ETCD Kurulum ve Yapılandırma Scripti"
    echo
    echo "Kullanım: $0 [seçenekler]"
    echo
    echo "Seçenekler:"
    for arg in "${!ARG_DESCRIPTIONS[@]}"; do
        printf "  %-25s %s\n" "$arg" "${ARG_DESCRIPTIONS[$arg]}"
    done
}

# Argümanları parse et
parse_arguments_etcd() {
    # Varsayılan değerleri ayarla
    declare -A config=(
        ["ETCD_IP"]="$DEFAULT_ETCD_IP"
        ["ETCD_CLIENT_PORT"]="$DEFAULT_ETCD_CLIENT_PORT"
        ["ETCD_PEER_PORT"]="$DEFAULT_ETCD_PEER_PORT"
        ["CLUSTER_TOKEN"]="$DEFAULT_CLUSTER_TOKEN"
        ["CLUSTER_STATE"]="$DEFAULT_CLUSTER_STATE"
        ["ETCD_NAME"]="$DEFAULT_ETCD_NAME"
        ["ELECTION_TIMEOUT"]="$DEFAULT_ELECTION_TIMEOUT"
        ["HEARTBEAT_INTERVAL"]="$DEFAULT_HEARTBEAT_INTERVAL"
        ["DATA_DIR"]="$DEFAULT_DATA_DIR"
    )

    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help
            return $HELP_CODE
            ;;
        ${ARG_KEYS[ETCD_IP]})
            config["ETCD_IP"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[ETCD_CLIENT_PORT]})
            config["ETCD_CLIENT_PORT"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[ETCD_PEER_PORT]})
            config["ETCD_PEER_PORT"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[CLUSTER_TOKEN]})
            config["CLUSTER_TOKEN"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[CLUSTER_STATE]})
            config["CLUSTER_STATE"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[ETCD_NAME]})
            config["ETCD_NAME"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[ELECTION_TIMEOUT]})
            config["ELECTION_TIMEOUT"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[HEARTBEAT_INTERVAL]})
            config["HEARTBEAT_INTERVAL"]="$2"
            shift 2
            ;;
        ${ARG_KEYS[DATA_DIR]})
            config["DATA_DIR"]="$2"
            shift 2
            ;;
        *)
            echo "Uyarı: Bilinmeyen argüman '$1' atlanıyor (belki docker argümanıdır)"
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