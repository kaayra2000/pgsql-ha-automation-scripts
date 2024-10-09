#!/bin/bash

# Varsayılan değerler
DEFAULT_INTERFACE="eth0"
DEFAULT_SQL_VIRTUAL_IP="10.207.80.20"
DEFAULT_DNS_VIRTUAL_IP="10.207.80.30"
DEFAULT_PRIORITY="100"
DEFAULT_STATE="BACKUP"
DEFAULT_SQL_CONTAINER="sql_container"
DEFAULT_DNS_CONTAINER="dns_container"

# Argüman ayrıştırma fonksiyonu
parse_arguments() {
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
}

# Keepalived kurulumu
install_keepalived() {
    echo "Keepalived kuruluyor..."
    sudo apt-get update
    sudo apt-get install -y keepalived
}

# Keepalived yapılandırması
configure_keepalived() {
    echo "Keepalived yapılandırılıyor..."
    
    cat << EOF | sudo tee /etc/keepalived/keepalived.conf
# SQL için VRRP yapılandırması
vrrp_script check_sql {
    script "docker inspect -f '{{.State.Running}}' $SQL_CONTAINER"
    interval 2
    weight 2
}

vrrp_instance VI_SQL {
    state $STATE
    interface $INTERFACE
    virtual_router_id 52
    priority $PRIORITY
    advert_int 1
    virtual_ipaddress {
        $SQL_VIRTUAL_IP
    }
    track_script {
        check_sql
    }
}

# DNS için VRRP yapılandırması
vrrp_script check_dns {
    script "docker inspect -f '{{.State.Running}}' $DNS_CONTAINER"
    interval 2
    weight 2
}

vrrp_instance VI_DNS {
    state $STATE
    interface $INTERFACE
    virtual_router_id 53
    priority $PRIORITY
    advert_int 1
    virtual_ipaddress {
        $DNS_VIRTUAL_IP
    }
    track_script {
        check_dns
    }
}
EOF

    echo "Keepalived yapılandırması tamamlandı."
}

# Keepalived servisini başlatma ve etkinleştirme
start_keepalived() {
    echo "Keepalived servisi başlatılıyor..."
    sudo systemctl start keepalived
    sudo systemctl enable keepalived
    echo "Keepalived servisi başlatıldı ve etkinleştirildi."
}

# Ana script
parse_arguments "$@"
install_keepalived
configure_keepalived
start_keepalived

echo "Keepalived kurulumu ve yapılandırması tamamlandı."
