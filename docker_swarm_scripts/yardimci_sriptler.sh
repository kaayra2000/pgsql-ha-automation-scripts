#!/bin/bash

SWARM_SERVIS_ADI="swarm_service"
SWARM_IMAGE_ADI="$SWARM_IMAGE_ADI"

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/../docker_scripts/create_image.sh

swarm_nodlari_listele() {
    docker node ls
}

swarm_servisleri_listele() {
    docker service ls
}

swarm_create_image() {
    create_image "$SWARM_IMAGE_ADI" "../docker_files" "docker_swarm" "$SCRIPT_DIR/.."
}

swarm_servisi_sil(){
    docker service rm $SWARM_SERVIS_ADI
}

swarm_create_example_service() {
    docker service create \
        --name "$SWARM_SERVIS_ADI" \
        --publish mode=host,target=$DNS_PORT,published=$DNS_DOCKER_FORWARD_PORT \
        --replicas 2 \
        --cap-add NET_ADMIN \
        --mount type=bind,src=/sys/fs/cgroup,dst=/sys/fs/cgroup,readonly \
        "$NODE1_IP:5000/$SWARM_IMAGE_ADI"
}

docker_registry_olustur() {
    docker run -d -p 5000:5000 --restart=always --name registry registry:2
}

docker_imaji_registryye_pushla() {
    # İmajı yeni adıyla tag'leyin
    docker tag "$SWARM_IMAGE_ADI" "$NODE1_IP:5000/$SWARM_IMAGE_ADI"

    # İmajı push edin
    docker push "$NODE1_IP:5000/$SWARM_IMAGE_ADI"
}