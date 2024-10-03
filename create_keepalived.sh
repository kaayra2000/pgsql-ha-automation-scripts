#!/bin/bash

# Keepalived kurulumu
install_keepalived() {
    echo "Keepalived kuruluyor..."
    sudo apt-get update
    sudo apt-get install -y keepalived
}

# Keepalived yapılandırması
configure_keepalived() {
    local INTERFACE=$1
    local VIRTUAL_IP=$2
    local PRIORITY=$3

    echo "Keepalived yapılandırılıyor..."
    
    cat << EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state MASTER
    interface $INTERFACE
    virtual_router_id 51
    priority $PRIORITY
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        $VIRTUAL_IP
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
if [ $# -ne 3 ]; then
    echo "Kullanım: $0 <ağ_arayüzü> <sanal_ip> <öncelik>"
    exit 1
fi

INTERFACE=$1
VIRTUAL_IP=$2
PRIORITY=$3

install_keepalived
configure_keepalived $INTERFACE $VIRTUAL_IP $PRIORITY
start_keepalived

echo "Keepalived kurulumu ve yapılandırması tamamlandı."
