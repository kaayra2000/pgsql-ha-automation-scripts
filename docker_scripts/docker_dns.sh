#!/bin/bash

<<COMMENT
    Buradaki değişkenler arguments.cfg dosyasından okunacak.
COMMENT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/create_image.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../default_variables.sh
source $SCRIPT_DIR/../general_functions.sh

# Docker konteynerını çalıştır
run_container() {
    docker run -d --rm --privileged \
        --name $DNS_CONTAINER_NAME \
        -p $DNS_DOCKER_FORWARD_PORT:$DNS_PORT/tcp -p $DNS_DOCKER_FORWARD_PORT:$DNS_PORT/udp \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --cap-add=NET_ADMIN \
        $DNS_IMAGE_NAME \
        /bin/bash -c "while true; do sleep 30; done"

        docker cp $ARGUMENT_CFG_FILE $DNS_CONTAINER_NAME:$DOCKER_BINARY_PATH

        docker exec -it $DNS_CONTAINER_NAME \
                /bin/bash -c    "$SHELL_PATH_IN_DOCKER/$DNS_SHELL_SCRIPT_NAME \
                                && service named start \
                                && service keepalived start"
}

# Ana fonksiyon
main() {
    # burada kullanıcıdan alınan argümanlar varsayılan argümanları ezeceği için problem yok
    parse_and_read_arguments "$@"
    create_image $DNS_IMAGE_NAME $DOCKERFILE_PATH $DNS_DOCKERFILE_NAME "$SCRIPT_DIR/.."
    check_success "Docker imajı oluşturulurken hata oluştu"
    run_container
    check_success "Docker konteynerı çalıştırılırken hata oluştu"
}

# Scripti çalıştır
main "$@"
