#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/create_image.sh
source $SCRIPT_DIR/argument_parser.sh
source $SCRIPT_DIR/../default_variables.sh
source $SCRIPT_DIR/../general_functions.sh

# Varsayılan değerler
DNS_PORT="53"
HOST_PORT="53"

# Sabit değerler
DOCKERFILE_PATH="../docker_files"
DOCKERFILE_NAME="docker_dns"
DNS_CONTAINER="dns_container"
IMAGE_NAME="dns_image"
SHELL_SCRIPT_NAME="create_dns_server.sh"

# Docker konteynerını çalıştır
run_container() {
    docker run -d --rm --privileged \
        --name $DNS_CONTAINER \
        -p $HOST_PORT:$DNS_PORT/tcp -p $HOST_PORT:$DNS_PORT/udp \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --cap-add=NET_ADMIN \
        $IMAGE_NAME \
        /bin/bash -c "$SHELL_PATH_IN_DOCKER/$SHELL_SCRIPT_NAME $DNS_PORT && \
                      service named start && \
                      service keepalived start && \
                      while true; do sleep 30; done"
}

# Ana fonksiyon
main() {
    # burada kullanıcıdan alınan argümanlar varsayılan argümanları ezeceği için problem yok
    dns_parser --dns-port $DNS_PORT --host-port $HOST_PORT "$@"
    check_success "Argümanları parse ederken hata oluştu"
    create_image $IMAGE_NAME $DOCKERFILE_PATH $DOCKERFILE_NAME "$SCRIPT_DIR/.."
    check_success "Docker imajı oluşturulurken hata oluştu"
    run_container
    check_success "Docker konteynerı çalıştırılırken hata oluştu"
}

# Scripti çalıştır
main "$@"
