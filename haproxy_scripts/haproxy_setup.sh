#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../general_functions.sh
ha_proxy_kur() {
    sudo apt install haproxy -y
    check_success "haproxy kurulurken bir hata oluştu."
}

ha_proxy_konfigure_et() {
    cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    maxconn 1000
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    retries 2
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    timeout check   5000
    maxconn 3000

frontend stats
    bind 0.0.0.0:$HAPROXY_BIND_PORT
    mode http
    default_backend stats_backend

backend stats_backend
    mode http
    stats enable
    stats uri /

frontend postgres_frontend
    bind 0.0.0.0:$PGSQL_BIND_PORT
    default_backend postgres_backend

backend postgres_backend
    mode tcp
    balance roundrobin
    option tcp-check
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server node-1 $NODE1_IP:$PGSQL_PORT maxconn 100 check
    server node-2 $NODE2_IP:$PGSQL_PORT maxconn 100 check
EOF
    check_success "HAProxy konfigürasyonu yapılırken bir hata oluştu."
}

enable_haproxy() {
    # Konfigürasyon dosyasını kontrol et
    echo "HAProxy konfigürasyon dosyası kontrol ediliyor..."
    sudo haproxy -c -f /etc/haproxy/haproxy.cfg
    check_success "HAProxy konfigürasyon dosyası hatalı."
    echo "HAProxy konfigürasyon dosyası başarıyla kontrol edildi."

    # HAProxy servisini başlat
    echo "HAProxy servisi başlatılıyor..."
    sudo service haproxy start
    check_success "HAProxy servisi başlatılırken bir hata oluştu."
    echo "HAProxy servisi başarıyla başlatıldı."
}
