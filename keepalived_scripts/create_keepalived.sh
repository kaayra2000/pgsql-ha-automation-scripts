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
check_and_parse_arguments $ARGUMENT_CFG_FILE "$@"
create_keepalived_user
setup_container_log $SQL_CONTAINER
setup_container_log $DNS_CONTAINER
configure_sudo_access
check_and_add_docker_permissions
install_keepalived
configure_keepalived
start_keepalived

echo "Keepalived kurulumu ve yapılandırması tamamlandı."
