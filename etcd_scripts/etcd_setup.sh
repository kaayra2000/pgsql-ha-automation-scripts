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
[Member]
ETCD_LISTEN_PEER_URLS="http://$ETCD_IP:$ETCD_PEER_PORT,http://127.0.0.1:7001"
ETCD_LISTEN_CLIENT_URLS="http://127.0.0.1:$ETCD_CLIENT_PORT,http://$ETCD_IP:$ETCD_CLIENT_PORT"
ETCD_DATA_DIR="$DATA_DIR"
ETCD_NAME="$ETCD_NAME"

[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$ETCD_IP:$ETCD_PEER_PORT"
ETCD_INITIAL_CLUSTER="$ETCD_NAME=http://$ETCD_IP:$ETCD_PEER_PORT"
ETCD_ADVERTISE_CLIENT_URLS="http://$ETCD_IP:$ETCD_CLIENT_PORT"
ETCD_INITIAL_CLUSTER_TOKEN="$CLUSTER_TOKEN"
ETCD_INITIAL_CLUSTER_STATE="$CLUSTER_STATE"

[Timer]
ETCD_ELECTION_TIMEOUT=$ELECTION_TIMEOUT
ETCD_HEARTBEAT_INTERVAL=$HEARTBEAT_INTERVAL

[Feature]
ETCD_ENABLE_V2=true
EOF
    check_success "etcd konfigürasyonu yapılırken bir hata oluştu."
}

etcd_etkinlestir() {
    echo "ETCD servisi durduruluyor..."
    sudo service etcd stop
    check_success "etcd servisi durdurulurken bir hata oluştu."

    echo "ETCD servisi yeniden başlatılıyor..."
    sudo service etcd start
    check_success "etcd servisi başlatılırken bir hata oluştu."

    # Servisin çalışıp çalışmadığını kontrol et
    if sudo service etcd status >/dev/null 2>&1; then
        echo "ETCD servisi başarıyla çalışıyor."
    else
        echo "UYARI: ETCD servisi başlatıldı ancak durumu kontrol edilemedi."
    fi
}