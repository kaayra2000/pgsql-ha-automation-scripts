#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/create_image.sh
source $SCRIPT_DIR/argument_parser.sh
source $SCRIPT_DIR/../default_variables.sh
source $SCRIPT_DIR/../general_functions.sh
# Varsayılan değerler
HAPROXY_PORT="8404"
HOST_PORT="8404"

# Sabit değerler
DOCKERFILE_PATH="docker_files"
DOCKERFILE_NAME="docker_sql"
SQL_CONTAINER="sql_container"
IMAGE_NAME="sql_image"
HAPROXY_SCRIPT_FOLDER="haproxy_scripts"
HAPROXY_SCRIPT_NAME="create_haproxy.sh"
ETCD_SCRIPT_FOLDER="etcd_scripts"
ETCD_SCRIPT_NAME="create_etcd.sh"

source $SCRIPT_DIR/../$HAPROXY_SCRIPT_FOLDER/argument_parser.sh
source $SCRIPT_DIR/../$ETCD_SCRIPT_FOLDER/argument_parser.sh
# Docker konteynerını çalıştır
run_container() {
    docker run -d --rm --privileged \
        --name $SQL_CONTAINER \
        -p $ETCD_CLIENT_PORT:$ETCD_CLIENT_PORT \
        -p $ETCD_PEER_PORT:$ETCD_PEER_PORT \
        -p $HAPROXY_BIND_PORT:$HAPROXY_BIND_PORT/tcp \
        -p $HAPROXY_BIND_PORT:$HAPROXY_BIND_PORT/udp \
        -p $POSTGRES_BIND_PORT:$POSTGRES_BIND_PORT/tcp \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --cap-add=NET_ADMIN \
        $IMAGE_NAME \
        /bin/bash -c "$SHELL_PATH_IN_DOCKER/$ETCD_SCRIPT_FOLDER/$ETCD_SCRIPT_NAME $args_string \
        && $SHELL_PATH_IN_DOCKER/$HAPROXY_SCRIPT_FOLDER/$HAPROXY_SCRIPT_NAME $args_string \
        && while true; do sleep 30; done"
}

args_string="$*"

# burada kullanıcıdan alınan argümanlar varsayılan argümanları ezeceği için problem yok
sql_parser --haproxy-port "$HAPROXY_PORT" --host-port "$HOST_PORT" $args_string
check_success "Argümanları parse ederken hata oluştu" false
parse_arguments_haproxy $args_string
check_success "HAProxy argümanları parse ederken hata oluştu" false
parse_arguments_etcd $args_string
check_success "ETCD argümanları parse ederken hata oluştu"
cd ..
create_image "$IMAGE_NAME" "$DOCKERFILE_PATH" "$DOCKERFILE_NAME" "$SCRIPT_DIR/.."
cd $SCRIPT_DIR
check_success "Docker imajı oluşturulurken hata oluştu"
run_container
check_success "Docker konteynerı çalıştırılırken hata oluştu"
