#!/bin/bash

<<COMMENT
    Buradaki değişkenler arguments.cfg dosyasından okunacak.
COMMENT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../general_functions.sh

etcd_kur() {
    sudo apt install etcd -y
    check_success "etcd kurulurken bir hata oluştu."
}

etcd_konfigure_et() {
    local ETCD_CONFIG_FILE="$1"
    cat <<EOF | sudo tee $ETCD_CONFIG_FILE
# etcd.conf.yml
name: '$ETCD_NAME'
data-dir: '$ETCD_DATA_DIR'

# Tüm interface'lerden dinle
listen-peer-urls: 'http://0.0.0.0:$ETCD_PEER_PORT'
listen-client-urls: 'http://0.0.0.0:$ETCD_CLIENT_PORT'

# Dışarıya duyurulacak adresler
initial-advertise-peer-urls: 'http://$ETCD_VIRTUAL_IP:$ETCD_PEER_PORT'
advertise-client-urls: 'http://$ETCD_VIRTUAL_IP:$ETCD_CLIENT_PORT'

initial-cluster: '$ETCD_NAME=http://$ETCD_VIRTUAL_IP:$ETCD_PEER_PORT'
initial-cluster-token: '$ETCD_CLUSTER_TOKEN'
initial-cluster-state: '$ETCD_CLUSTER_KEEPALIVED_STATE'

election-timeout: $ETCD_ELECTION_TIMEOUT
heartbeat-interval: $ETCD_HEARTBEAT_INTERVAL

enable-v2: true
EOF
    check_success "etcd konfigürasyonu yapılırken bir hata oluştu."

    set_permissions "$ETCD_USER" "$ETCD_CONFIG_FILE" "600"
    return $?
}

start_etcd() {
    local ETCD_CLIENT_PORT="$1"
    if [ -z "$ETCD_CLIENT_PORT" ]; then
        echo "HATA: Port numarası belirtilmedi!"
        return 1
    fi

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
            echo "UYARI: ETCD servisi çalışıyor fakat API şu anlık yanıt vermiyor (port: ${ETCD_CLIENT_PORT})"
            return 0
        fi
    else
        echo "HATA: ETCD servisi başlatılamadı!"
        service etcd status
        return 1
    fi
}


# Bu fonksiyon, verilen yml dosyasının yolunu alır ve /etc/init.d/etcd dosyasındaki DAEMON_ARGS satırını günceller.
# Amacı etcd servisini başlatırken yml dosyasını kullanmaktır.
update_etcd_init_script() {
    local ETCD_CONFIG_FILE="$1"

    # Yml dosyasının varlığını kontrol et
    if [ ! -f "$ETCD_CONFIG_FILE" ]; then
        echo "HATA: Belirtilen yml dosyası bulunamadı: $ETCD_CONFIG_FILE"
        return 1
    fi

    # /etc/init.d/etcd dosyasının varlığını kontrol et
    if [ ! -f "$DOCKER_INITD_PATH/etcd" ]; then
        echo "HATA: $DOCKER_INITD_PATH/etcd dosyası bulunamadı."
        return 1
    fi

    # DAEMON_ARGS satırını güncelle veya ekle
    if grep -q "^DAEMON_ARGS=" $DOCKER_INITD_PATH/etcd; then
        # DAEMON_ARGS satırı varsa güncelle
        sudo sed -i "s|^DAEMON_ARGS=.*|DAEMON_ARGS=\"--config-file=$ETCD_CONFIG_FILE\"|" $DOCKER_INITD_PATH/etcd
        echo "DAEMON_ARGS başarıyla güncellendi: --config-file=$ETCD_CONFIG_FILE"
    else
        # DAEMON_ARGS satırı yoksa, [ -x "$DAEMON" ] || exit 0 satırının üstüne ekle
        sudo sed -i "/^\[ -x \"\$DAEMON\" \] || exit 0/i DAEMON_ARGS=\"--config-file=$ETCD_CONFIG_FILE\"" $DOCKER_INITD_PATH/etcd
        echo "DAEMON_ARGS satırı eklendi: --config-file=$ETCD_CONFIG_FILE"
    fi
    return 0
}

create_and_configure_neccessary_etcd_files() {
    if ! check_and_create_directory "$ETCD_DATA_DIR"; then
        return 1
    fi

    if ! check_and_create_directory "$ETCD_CONFIG_DIR"; then
        return 1
    fi

    # Dizinler oluşturulduktan sonra kullanıcı kontrolü
    if ! check_user_exists "$ETCD_USER"; then
        echo "Hata: Kullanıcı $ETCD_USER mevcut değil. Devam edilemiyor."
        return 1
    fi

    # Kullanıcı varsa, dizinlerin sahipliğini ve izinlerini ayarla
    if ! set_permissions "$ETCD_USER" "$ETCD_DATA_DIR" "700"; then
        echo "Hata: $ETCD_DATA_DIR için izinler ayarlanamadı."
        return 1
    fi

    if ! set_permissions "$ETCD_USER" "$ETCD_CONFIG_DIR" "700"; then
        echo "Hata: $ETCD_CONFIG_DIR için izinler ayarlanamadı."
        return 1
    fi
    return 0
}