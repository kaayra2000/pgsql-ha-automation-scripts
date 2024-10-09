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

# keepalived_script kullanıcısını oluşturma
create_keepalived_user() {
    if ! id "keepalived_script" &>/dev/null; then
        echo "keepalived_script kullanıcısı oluşturuluyor..."
        sudo useradd -r -s /sbin/nologin keepalived_script
        echo "keepalived_script kullanıcısı oluşturuldu."
    else
        echo "keepalived_script kullanıcısı zaten mevcut."
    fi
}

# Keepalived kurulumu
install_keepalived() {
    if ! command -v keepalived &> /dev/null
    then
        echo "Keepalived kuruluyor..."
        sudo apt-get update
        sudo apt-get install -y keepalived
        echo "Keepalived kurulumu tamamlandı."
    else
        echo "Keepalived zaten kurulu."
    fi
}

# Keepalived yapılandırması
configure_keepalived() {
    echo "Keepalived yapılandırılıyor..."
    
    cat << EOF | sudo tee /etc/keepalived/keepalived.conf
global_defs {
    script_user keepalived_script
    enable_script_security
}

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
    if systemctl is-active --quiet keepalived; then
        echo "Keepalived servisi zaten çalışıyor. Yeniden başlatılıyor..."
        sudo systemctl restart keepalived
    else
        echo "Keepalived servisi başlatılıyor..."
        sudo systemctl start keepalived
    fi
    
    if ! systemctl is-enabled --quiet keepalived; then
        echo "Keepalived servisi etkinleştiriliyor..."
        sudo systemctl enable keepalived
    else
        echo "Keepalived servisi zaten etkinleştirilmiş."
    fi
    
    echo "Keepalived servisi başlatıldı/yeniden başlatıldı ve etkinleştirildi."
}

# Ana script
parse_arguments "$@"
create_keepalived_user
install_keepalived
configure_keepalived
start_keepalived

echo "Keepalived kurulumu ve yapılandırması tamamlandı."
