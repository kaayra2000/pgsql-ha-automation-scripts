#!/bin/bash

<<COMMENT
    Buradaki değişkenler arguments.cfg dosyasından okunacak.
COMMENT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../general_functions.sh
ha_proxy_kur() {
    sudo apt install haproxy -y
    check_success "haproxy kurulurken bir hata oluştu."
}

ha_proxy_konfigure_et() {
    cat <<EOF | sudo tee $HAPROXY_CONFIG_FILE
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

start_haproxy() {
    # Konfigürasyon dosyasını kontrol et
    echo "HAProxy konfigürasyon dosyası kontrol ediliyor..."
    sudo haproxy -c -f $HAPROXY_CONFIG_FILE
    check_success "HAProxy konfigürasyon dosyası hatalı."
    echo "HAProxy konfigürasyon dosyası başarıyla kontrol edildi."

    # HAProxy servisini başlat
    echo "HAProxy servisi başlatılıyor..."
    sudo service haproxy start
    check_success "HAProxy servisi başlatılırken bir hata oluştu."
    echo "HAProxy servisi başarıyla başlatıldı."
}

update_haproxy_init_script() {
    local HAPROXY_INIT_SCRIPT="$DOCKER_INITD_PATH/haproxy"

    # HAProxy init script'in varlığını kontrol et
    if [ ! -f "$HAPROXY_INIT_SCRIPT" ]; then
        echo "HATA: $HAPROXY_INIT_SCRIPT bulunamadı."
        return 1
    fi

    # haproxy_debug fonksiyonunu ekle
    if grep -q "haproxy_debug()" "$HAPROXY_INIT_SCRIPT"; then
        echo "haproxy_debug fonksiyonu zaten mevcut."
    else
        echo "haproxy_debug fonksiyonu ekleniyor..."
        sudo sed -i "/^check_haproxy_config()/i \\
haproxy_debug() {\\
    check_haproxy_config\\
    echo \"Starting haproxy in debug mode...\"\\
    \$HAPROXY -f \"\$CONFIG\" -db \$EXTRAOPTS\\
}\\
" "$HAPROXY_INIT_SCRIPT"
        echo "haproxy_debug fonksiyonu eklendi."
    fi

    # Usage satırını güncelle
    if grep -q "{start|stop|reload|restart|status|debug}" "$HAPROXY_INIT_SCRIPT"; then
        echo "Usage satırı zaten güncel."
    else
        echo "Usage satırı güncelleniyor..."
        sudo sed -i 's/{start|stop|reload|restart|status}/{start|stop|reload|restart|status|debug}/' "$HAPROXY_INIT_SCRIPT"
        echo "Usage satırı güncellendi."
    fi

    # Case yapısına debug seçeneğini ekle
    if grep -q -E '^\s*debug\)' "$HAPROXY_INIT_SCRIPT"; then
        echo "Case yapısında debug seçeneği zaten mevcut."
    else
        echo "Case yapısına debug seçeneği ekleniyor..."
        sudo sed -i "/case \"\$1\" in/a \\
    debug)\\
        haproxy_debug\\
        ;;\\
" "$HAPROXY_INIT_SCRIPT"
        echo "Case yapısına debug seçeneği eklendi."
    fi

    echo "HAProxy init scripti başarıyla güncellendi."
}