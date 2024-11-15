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
    echo "ETCD servisi durduruluyor..."
    pkill etcd || true
    
    echo "ETCD servisi başlatılıyor..."
    nohup etcd --config-file=/etc/etcd/etcd.conf.yml > /var/log/etcd.log 2>&1 &
    
    # Kısa bir kontrol
    if pgrep etcd >/dev/null; then
        echo "ETCD servisi başarıyla çalışıyor."
        return 0
    else
        echo "HATA: ETCD servisi başlatılamadı!"
        return 1
    fi
}