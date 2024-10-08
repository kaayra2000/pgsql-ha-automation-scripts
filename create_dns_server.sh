#!/bin/bash

# Fonksiyonlar

check_integer() {
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Hata: Lütfen geçerli bir port numarası girin (0-65535 arası)."
        exit 1
    fi
    if [ "$1" -lt 1 ] || [ "$1" -gt 65535 ]; then
        echo "Hata: Port numarası 1-65535 arasında olmalıdır."
        exit 1
    fi
}

check_ufw_status() {
    if ! command -v ufw &> /dev/null; then
        echo "UFW yüklü değil. Firewall ayarları yapılmayacak."
        return 1
    fi
    if sudo ufw status | grep -q "Status: active"; then
        return 0
    else
        echo "UFW aktif değil. Firewall ayarları yapılmayacak."
        return 1
    fi
}

install_bind9() {
    echo "BIND9 kuruluyor..."
    sudo apt-get update
    sudo apt-get install -y bind9 bind9utils bind9-doc
}

configure_bind9() {
    local PORT=$1
    echo "BIND9 yapılandırılıyor..."
    
    # named.conf.options dosyasını düzenle
    cat << EOF | sudo tee /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    listen-on port $PORT { any; };
    allow-query { any; };
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
    forward only;
};
EOF

    # named.conf.local dosyasını düzenle
    cat << EOF | sudo tee /etc/bind/named.conf.local
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
};

zone "server" {
    type master;
    file "/etc/bind/db.server";
};
EOF

    # Örnek zone dosyası oluştur (example.com)
    cat << EOF | sudo tee /etc/bind/db.example.com
\$TTL    604800
@       IN      SOA     example.com. admin.example.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.example.com.
@       IN      A       127.0.0.1
ns      IN      A       127.0.0.1
EOF

    # Yeni zone dosyası oluştur (server)
    cat << EOF | sudo tee /etc/bind/db.server
\$TTL    604800
@       IN      SOA     server. admin.server. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.server.
@       IN      A       10.207.80.22
ns      IN      A       10.207.80.22
EOF

    # BIND9 servisini yeniden başlat
    service named restart
}

# Ana script

if [ $# -ne 1 ]; then
    echo "Kullanım: $0 <port>"
    exit 1
fi

PORT=$1

check_integer "$PORT"

install_bind9
configure_bind9 "$PORT"
open_firewall_port "$PORT"

echo "DNS sunucusu $PORT portunda başarıyla kuruldu."
