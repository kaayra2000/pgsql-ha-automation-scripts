#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../general_functions.sh
ha_proxy_kur() {
    sudo apt install haproxy -y
    hata_kontrol "haproxy kurulurken bir hata oluştu."
}

ha_proxy_konfigure_et() {
    local NODE1_IP="$1"
    local NODE2_IP="$2"
    local ETCD_IP="$3"
    local HAPROXY_BIND_PORT="$4"
    local PGSQL_PORT="$5"
    local HAPROXY_PORT="$6"
    cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    maxconn 1000

defaults
    log global
    mode tcp
    retries 2
    timeout client 30m
    timeout connect 4s
    timeout server 30m
    timeout check 5s

listen stats
    mode http
    bind $ETCD_IP:$HAPROXY_BIND_PORT
    stats enable
    stats uri /

listen postgres
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server node-1 $NODE1_IP:$PGSQL_PORT maxconn 100 check port $HAPROXY_PORT
    server node-2 $NODE2_IP:$PGSQL_PORT maxconn 100 check port $HAPROXY_PORT
EOF
    hata_kontrol "haproxy konfigürasyonu yapılırken bir hata oluştu."
}

ha_proxy_etkinlestir() {
    # Konfigürasyon dosyası kontrolü
    sudo haproxy -c -f /etc/haproxy/haproxy.cfg
    hata_kontrol "haproxy konfigürasyon dosyası hatalı."

    sudo systemctl start haproxy
    hata_kontrol "haproxy servisi başlatılırken bir hata oluştu."
    sudo systemctl enable haproxy
    hata_kontrol "haproxy servisi etkinleştirilirken bir hata oluştu."
    sudo systemctl restart haproxy
    hata_kontrol "haproxy servisi yeniden başlatılırken bir hata oluştu."
}
