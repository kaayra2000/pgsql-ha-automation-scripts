#!/bin/bash
# Varsayılan değerler
DEFAULT_NODE1_IP="10.207.80.21"
DEFAULT_NODE2_IP="10.207.80.22"
DEFAULT_ETCD_IP="10.207.80.23"
DEFAULT_HAPROXY_BIND_PORT="7000"
DEFAULT_PGSQL_PORT="5432"
DEFAULT_HAPROXY_PORT="8008"
# Argüman tanımlamaları
declare -A ARG_DESCRIPTIONS=(
    ["--node1-ip"]="Birinci node IP adresi (varsayılan: $DEFAULT_NODE1_IP)"
    ["--node2-ip"]="İkinci node IP adresi (varsayılan: $DEFAULT_NODE2_IP)"
    ["--etcd-ip"]="ETCD sunucu IP adresi (varsayılan: $DEFAULT_ETCD_IP)"
    ["--haproxy-bind-port"]="HAProxy bind portu (varsayılan: $DEFAULT_HAPROXY_BIND_PORT)"
    ["--pgsql-port"]="PostgreSQL portu (varsayılan: $DEFAULT_PGSQL_PORT)"
    ["--haproxy-port"]="HAProxy kontrol portu (varsayılan: $DEFAULT_HAPROXY_PORT)"
)

# Yardım mesajını göster
show_help() {
    echo "HAProxy Kurulum ve Yapılandırma Scripti"
    echo
    echo "Kullanım: $0 [seçenekler]"
    echo
    echo "Seçenekler:"
    for arg in "${!ARG_DESCRIPTIONS[@]}"; do
        printf "  %-25s %s\n" "$arg" "${ARG_DESCRIPTIONS[$arg]}"
    done
}

# Argümanları parse et
parse_arguments() {
    NODE1_IP="$DEFAULT_NODE1_IP"
    NODE2_IP="$DEFAULT_NODE2_IP"
    ETCD_IP="$DEFAULT_ETCD_IP"
    HAPROXY_BIND_PORT= "$DEFAULT_HAPROXY_BIND_PORT"
    PGSQL_PORT="$DEFAULT_PGSQL_PORT"
    HAPROXY_PORT="$DEFAULT_HAPROXY_PORT"
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help
            exit 0
            ;;
        --node1-ip)
            NODE1_IP="$2"
            shift 2
            ;;
        --node2-ip)
            NODE2_IP="$2"
            shift 2
            ;;
        --etcd-ip)
            ETCD_IP="$2"
            shift 2
            ;;
        --haproxy-bind-port)
            HAPROXY_BIND_PORT="$2"
            shift 2
            ;;
        --pgsql-port)
            PGSQL_PORT="$2"
            shift 2
            ;;
        --haproxy-port)
            HAPROXY_PORT="$2"
            shift 2
            ;;
        *)
            echo "Hata: Bilinmeyen argüman '$1'"
            show_help
            exit 1
            ;;
        esac
    done
    export NODE1_IP
    export NODE2_IP
    export ETCD_IP
    export HAPROXY_BIND_PORT
    export PGSQL_PORT
    export HAPROXY_PORT
}
