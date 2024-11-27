#!/bin/bash

# Keepalived kurulumu
install_keepalived() {
    if ! command -v keepalived &>/dev/null; then
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

    cat <<EOF | sudo tee /etc/keepalived/keepalived.conf
global_defs {
    script_user keepalived_script
    enable_script_security
}

# SQL için VRRP yapılandırması
vrrp_script check_sql {
    script "$(create_checkscript $SQL_CONTAINER_NAME)"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance VI_SQL {
    state $KEEPALIVED_STATE
    interface $KEEPALIVED_INTERFACE
    virtual_router_id 52
    priority $KEEPALIVED_PRIORITY
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
    script "$(create_checkscript $DNS_CONTAINER_NAME)"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance VI_DNS {
    state $KEEPALIVED_STATE
    interface $KEEPALIVED_INTERFACE
    virtual_router_id 53
    priority $KEEPALIVED_PRIORITY
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
