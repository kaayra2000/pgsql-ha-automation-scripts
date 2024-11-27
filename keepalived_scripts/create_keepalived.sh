#!/bin/bash

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Diğer scriptleri import etme
source "$SCRIPT_DIR/../argument_parser.sh"
source "$SCRIPT_DIR/user_management.sh"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/keepalived_setup.sh"
source "$SCRIPT_DIR/container_scripts.sh"

# Ana akış
parse_and_read_arguments "$@"
create_keepalived_user
setup_container_log $SQL_CONTAINER_NAME
setup_container_log $DNS_CONTAINER_NAME
configure_sudo_access
check_and_add_docker_permissions
install_keepalived
configure_keepalived
start_keepalived

echo "Keepalived kurulumu ve yapılandırması tamamlandı."
