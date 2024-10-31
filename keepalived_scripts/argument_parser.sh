#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../default_variables.sh # varsayilan_degiskenler.sh dosyasındaki değişkenleri kullanmak için

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
