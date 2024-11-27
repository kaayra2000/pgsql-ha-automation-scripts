#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/create_image.sh
source $SCRIPT_DIR/../default_variables.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh

# Docker konteynerını çalıştır
run_container() {
    docker run -d --rm --privileged \
        --name $SQL_CONTAINER_NAME \
        -p $ETCD_CLIENT_PORT:$ETCD_CLIENT_PORT \
        -p $ETCD_PEER_PORT:$ETCD_PEER_PORT \
        -p $HAPROXY_BIND_PORT:$HAPROXY_BIND_PORT/tcp \
        -p $HAPROXY_BIND_PORT:$HAPROXY_BIND_PORT/udp \
        -p $PGSQL_BIND_PORT:$PGSQL_BIND_PORT/tcp \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --cap-add=NET_ADMIN \
        $SQL_IMAGE_NAME \
        /bin/bash -c "$SHELL_PATH_IN_DOCKER/$ETCD_SCRIPT_FOLDER/$ETCD_SCRIPT_NAME \
        && $SHELL_PATH_IN_DOCKER/$HAPROXY_SCRIPT_FOLDER/$HAPROXY_SCRIPT_NAME \
        && while true; do sleep 30; done"
}
parse_and_read_arguments "$@"
create_image "$SQL_IMAGE_NAME" "$DOCKERFILE_PATH" "$SQL_DOCKERFILE_NAME" "$SCRIPT_DIR/.."
cd $SCRIPT_DIR
check_success "Docker imajı oluşturulurken hata oluştu"
run_container
check_success "Docker konteynerı çalıştırılırken hata oluştu"
