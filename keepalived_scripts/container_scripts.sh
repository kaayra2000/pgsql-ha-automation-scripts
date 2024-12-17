#!/bin/bash

# Konteyner ayakta mı scripti oluşturma (komutların çoğu log için yazıldı)
create_docker_checkscript() {
    local CONTAINER_NAME=$1

    cat <<EOF
sudo -n /usr/bin/docker inspect -f {{.State.Running}} ${CONTAINER_NAME}
EOF
}

create_service_checkscript() {
    local CONTAINER_NAME="$1"
    local SERVICE_NAME="$2"
    cat <<EOF
sudo docker exec "${CONTAINER_NAME}" service "${SERVICE_NAME}" status
EOF
}