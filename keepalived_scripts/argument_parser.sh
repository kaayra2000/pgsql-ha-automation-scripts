#!/bin/bash

# Varsayılan değerler
DEFAULT_INTERFACE="enp0s3"
DEFAULT_SQL_VIRTUAL_IP="10.207.80.20"
DEFAULT_DNS_VIRTUAL_IP="10.207.80.30"
DEFAULT_PRIORITY="100"
DEFAULT_STATE="BACKUP"
DEFAULT_SQL_CONTAINER="sql_container"
DEFAULT_DNS_CONTAINER="dns_container"
DOCKER_BINARY_PATH="/usr/bin/docker"

parse_arguments() {
    # Varsayılan değişkenleri dışa aktarma
    INTERFACE=$DEFAULT_INTERFACE
    SQL_VIRTUAL_IP=$DEFAULT_SQL_VIRTUAL_IP
    DNS_VIRTUAL_IP=$DEFAULT_DNS_VIRTUAL_IP
    PRIORITY=$DEFAULT_PRIORITY
    STATE=$DEFAULT_STATE
    SQL_CONTAINER=$DEFAULT_SQL_CONTAINER
    DNS_CONTAINER=$DEFAULT_DNS_CONTAINER

    while [[ $# -gt 0 ]]; do
        case $1 in
        --interface)
            INTERFACE="$2"
            shift 2
            ;;
        --sql-virtual-ip)
            SQL_VIRTUAL_IP="$2"
            shift 2
            ;;
        --dns-virtual-ip)
            DNS_VIRTUAL_IP="$2"
            shift 2
            ;;
        --priority)
            PRIORITY="$2"
            shift 2
            ;;
        --state)
            if [[ "$2" != "MASTER" && "$2" != "BACKUP" ]]; then
                echo "Hata: State sadece MASTER veya BACKUP olabilir."
                exit 1
            fi
            STATE="$2"
            shift 2
            ;;
        --sql-container)
            SQL_CONTAINER="$2"
            shift 2
            ;;
        --dns-container)
            DNS_CONTAINER="$2"
            shift 2
            ;;
        *)
            echo "Bilinmeyen argüman: $1"
            exit 1
            ;;
        esac
    done

    # Varsayılan değerlerin export edilmesi
    export INTERFACE
    export SQL_VIRTUAL_IP
    export DNS_VIRTUAL_IP
    export PRIORITY
    export STATE
    export SQL_CONTAINER
    export DNS_CONTAINER
}
