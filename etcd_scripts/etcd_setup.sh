#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../general_functions.sh

etcd_kur() {
    sudo apt install etcd -y
    check_success "etcd kurulurken bir hata oluştu."
}

etcd_konfigure_et() {
    local ETCD_IP="$1"
    local ETCD_CLIENT_PORT="$2"
    local ETCD_PEER_PORT="$3"
    local CLUSTER_TOKEN="$4"
    local CLUSTER_STATE="$5"
    local ETCD_NAME="$6"
    local ELECTION_TIMEOUT="$7"
    local HEARTBEAT_INTERVAL="$8"
    local DATA_DIR="$9"
    local ETCD_CONFIG_FILE="${10}"

    cat <<EOF | sudo tee $ETCD_CONFIG_FILE
# etcd.conf.yml
name: '$ETCD_NAME'
data-dir: '$DATA_DIR'

# Tüm interface'lerden dinle
listen-peer-urls: 'http://0.0.0.0:$ETCD_PEER_PORT'
listen-client-urls: 'http://0.0.0.0:$ETCD_CLIENT_PORT'

# Dışarıya duyurulacak adresler
initial-advertise-peer-urls: 'http://$ETCD_IP:$ETCD_PEER_PORT'
advertise-client-urls: 'http://$ETCD_IP:$ETCD_CLIENT_PORT'

initial-cluster: '$ETCD_NAME=http://$ETCD_IP:$ETCD_PEER_PORT'
initial-cluster-token: '$CLUSTER_TOKEN'
initial-cluster-state: '$CLUSTER_STATE'

election-timeout: $ELECTION_TIMEOUT
heartbeat-interval: $HEARTBEAT_INTERVAL

enable-v2: true
EOF
    check_success "etcd konfigürasyonu yapılırken bir hata oluştu."
}

etcd_etkinlestir() {
    local ETCD_CLIENT_PORT="$1"
    if [ -z "$ETCD_CLIENT_PORT" ]; then
        echo "HATA: Port numarası belirtilmedi!"
        return 1
    fi

    echo "ETCD servisi durduruluyor..."
    service etcd stop
    
    echo "ETCD servisi başlatılıyor..."
    service etcd start

    # Servis durumunu kontrol et
    if service etcd status >/dev/null 2>&1; then
        echo "ETCD servisi başarıyla çalışıyor."
        # API'nin çalışıp çalışmadığını kontrol et
        if curl -s "http://127.0.0.1:${ETCD_CLIENT_PORT}/health" >/dev/null 2>&1; then
            echo "ETCD API aktif ve sağlıklı (port: ${ETCD_CLIENT_PORT})"
            return 0
        else
            echo "UYARI: ETCD servisi çalışıyor fakat API yanıt vermiyor (port: ${ETCD_CLIENT_PORT})"
            return 2
        fi
    else
        echo "HATA: ETCD servisi başlatılamadı!"
        service etcd status
        return 1
    fi
}


# Bu fonksiyon, verilen yml dosyasının yolunu alır ve /etc/init.d/etcd dosyasındaki DAEMON_ARGS satırını günceller.
# Amacı etcd servisini başlatırken yml dosyasını kullanmaktır.
update_daemon_args() {
    local ETCD_CONFIG_FILE="$1"

    # Yml dosyasının varlığını kontrol et
    if [ ! -f "$ETCD_CONFIG_FILE" ]; then
        echo "HATA: Belirtilen yml dosyası bulunamadı: $ETCD_CONFIG_FILE"
        return 1
    fi

    # /etc/init.d/etcd dosyasının varlığını kontrol et
    if [ ! -f "/etc/init.d/etcd" ]; then
        echo "HATA: /etc/init.d/etcd dosyası bulunamadı."
        return 1
    fi

    # DAEMON_ARGS satırını güncelle veya ekle
    if grep -q "^DAEMON_ARGS=" /etc/init.d/etcd; then
        # DAEMON_ARGS satırı varsa güncelle
        sudo sed -i "s|^DAEMON_ARGS=.*|DAEMON_ARGS=\"--config-file=$ETCD_CONFIG_FILE\"|" /etc/init.d/etcd
        echo "DAEMON_ARGS başarıyla güncellendi: --config-file=$ETCD_CONFIG_FILE"
    else
        # DAEMON_ARGS satırı yoksa, [ -x "$DAEMON" ] || exit 0 satırının üstüne ekle
        sudo sed -i "/^\[ -x \"\$DAEMON\" \] || exit 0/i DAEMON_ARGS=\"--config-file=$ETCD_CONFIG_FILE\"" /etc/init.d/etcd
        echo "DAEMON_ARGS satırı eklendi: --config-file=$ETCD_CONFIG_FILE"
    fi
}