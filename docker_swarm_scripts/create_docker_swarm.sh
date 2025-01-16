#!/bin/bash

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/docker_swarm_setup.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh

parse_and_read_arguments "$@"

update_and_install_docker   # Docker'ı kur

enable_docker               # Docker'ı başlat ve etkinleştir

add_user_to_docker_group    # Kullanıcıyı docker grubuna ekle

initialize_docker_swarm     # Docker Swarm'ı başlat