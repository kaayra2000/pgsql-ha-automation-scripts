#!/bin/bash

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/swarm_initializer_funcitons.sh
source $SCRIPT_DIR/set_swarm_node_variables.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh

parse_and_read_arguments "$@"
set_swarm_node_variables || exit 1

update_and_install_docker || exit 1 # Docker'ı kur

enable_docker || exit 1 # Docker'ı başlat ve etkinleştir

add_user_to_docker_group || exit 1 # Kullanıcıyı docker grubuna ekle

if [ "$IS_NODE_1" = true ]; then
    initialize_docker_swarm_manager || exit 1 # Docker Swarm'ı manager olarak oluştur
    write_swarm_worker_token || exit 1 # Başka cihaz eğer bu tokenla join olursa worker olur
else
    join_swarm_as_worker || exit 1 # Docker Swarm'a worker olarak katıl
fi
