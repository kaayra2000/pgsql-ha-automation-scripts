#!/bin/bash

<<COMMENT
    Buradaki değişkenler arguments.cfg dosyasından okunacak.
COMMENT

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
        -p $HAPROXY_PORT:$HAPROXY_PORT \
        -p $PGSQL_PORT:$PGSQL_PORT \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -v $POSTGRES_DATA_ROOT_VOLUME_NAME:$POSTGRES_DATA_ROOT_DIR \
        -v $PATRONI_LOG_VOLUME_NAME:$PATRONI_LOG_DIR \
        --cap-add=NET_ADMIN \
        $SQL_IMAGE_NAME \
        /bin/bash -c "while true; do sleep 30; done"

    docker cp $ARGUMENT_CFG_FILE $SQL_CONTAINER_NAME:$DOCKER_BINARY_PATH

    docker exec -it $SQL_CONTAINER_NAME \
        /bin/bash -c    "$SHELL_PATH_IN_DOCKER/$ETCD_SCRIPT_FOLDER/$ETCD_SCRIPT_NAME \
                        && $SHELL_PATH_IN_DOCKER/$HAPROXY_SCRIPT_FOLDER/$HAPROXY_SCRIPT_NAME \
                        && $SHELL_PATH_IN_DOCKER/$PATRONI_SCRIPT_FOLDER/$PATRONI_SCRIPT_NAME"
}
parse_and_read_arguments "$@"
docker volume create $POSTGRES_DATA_ROOT_VOLUME_NAME $PATRONI_LOG_VOLUME_NAME
create_image "$SQL_IMAGE_NAME" "$DOCKERFILE_PATH" "$SQL_DOCKERFILE_NAME" "$SCRIPT_DIR/.."
cd $SCRIPT_DIR
check_success "Docker imajı oluşturulurken hata oluştu"
run_container
check_success "Docker konteynerı çalıştırılırken hata oluştu"
