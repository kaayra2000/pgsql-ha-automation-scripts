#!/bin/bash

<<COMMENT
    Buradaki değişkenler arguments.cfg dosyasından okunacak.
COMMENT

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Diğer scriptleri import etme
source "$SCRIPT_DIR/../general_functions.sh"
source "$SCRIPT_DIR/user_management.sh"
source "$SCRIPT_DIR/keepalived_setup.sh"
source "$SCRIPT_DIR/container_scripts.sh"

# Ana akış
parse_and_read_arguments "$@"
create_keepalived_user
configure_sudo_access
check_and_add_docker_permissions
install_keepalived
configure_keepalived
start_keepalived

echo "Keepalived kurulumu ve yapılandırması tamamlandı."
