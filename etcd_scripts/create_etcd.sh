#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/etcd_setup.sh
source $SCRIPT_DIR/argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh
ETCD_CONFIG_DIR="/etc/etcd"
ETCD_CONFIG_FILE="$ETCD_CONFIG_DIR/etcd.conf"
ETCD_USER="etcd"
parse_arguments_etcd "$@"
# IP ve port validasyonları
validate_ip $ETCD_IP
validate_port $ETCD_CLIENT_PORT
validate_port $ETCD_PEER_PORT
# Sayısal değer kontrolü
if ! validate_number "$ELECTION_TIMEOUT" "Election timeout" 1000; then
    exit 1
fi

if ! validate_number "$HEARTBEAT_INTERVAL" "Heartbeat interval" 100; then
    exit 1
fi

# Dizin kontrolü
if ! check_directory "$DATA_DIR"; then
    exit 1
fi

if ! check_directory "$ETCD_CONFIG_DIR"; then
    exit 1
fi

# Dizinler oluşturulduktan sonra kullanıcı kontrolü
if ! check_user_exists "$ETCD_USER"; then
    echo "Error: User $ETCD_USER does not exist. Cannot proceed."
    exit 1
fi

# Kullanıcı varsa, dizinlerin sahipliğini ve izinlerini ayarla
if ! set_permissions "$ETCD_USER" "$DATA_DIR" "700"; then
    echo "Error: Failed to set permissions for $DATA_DIR"
    exit 1
fi

if ! set_permissions "$ETCD_USER" "$ETCD_CONFIG_DIR" "700"; then
    echo "Error: Failed to set permissions for $ETCD_CONFIG_DIR"
    exit 1
fi

# ETCD kurulum ve konfigürasyon
etcd_kur
etcd_konfigure_et \
    "$ETCD_IP" \
    "$ETCD_CLIENT_PORT" \
    "$ETCD_PEER_PORT" \
    "$CLUSTER_TOKEN" \
    "$CLUSTER_STATE" \
    "$ETCD_NAME" \
    "$ELECTION_TIMEOUT" \
    "$HEARTBEAT_INTERVAL" \
    "$DATA_DIR" \
    "$ETCD_CONFIG_FILE"
if ! set_permissions "$ETCD_USER" "$ETCD_CONFIG_FILE" "600"; then
    echo "Error: Failed to set permissions for $ETCD_CONFIG_FILE"
    exit 1
fi
etcd_etkinlestir