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

# Docker konteynerını çalıştır
run_container() {
    docker run -d --rm --privileged \
        --name $SQL_CONTAINER \
        -p $HOST_PORT:$HAPROXY_PORT/tcp -p $HOST_PORT:$HAPROXY_PORT/udp \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --cap-add=NET_ADMIN \
        $IMAGE_NAME \
        /bin/bash -c "$SHELL_PATH_IN_DOCKER/$HAPROXY_SCRIPT_FOLDER/$HAPROXY_SCRIPT_NAME $@ \
        && while true; do sleep 30; done"
}
# burada kullanıcıdan alınan argümanlar varsayılan argümanları ezeceği için problem yok
sql_parser --haproxy-port "$HAPROXY_PORT" --host-port "$HOST_PORT" "$@"
check_success "Argümanları parse ederken hata oluştu" false
cd ..
create_image "$IMAGE_NAME" "$DOCKERFILE_PATH" "$DOCKERFILE_NAME" "$SCRIPT_DIR/.."
cd $SCRIPT_DIR
check_success "Docker imajı oluşturulurken hata oluştu"
run_container
check_success "Docker konteynerı çalıştırılırken hata oluştu"
