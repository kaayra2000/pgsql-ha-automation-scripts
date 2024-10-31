#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/create_image.sh

# Varsayılan değerler
DNS_PORT="53"
HOST_PORT="53"

# Sabit değerler
DOCKERFILE_PATH="../docker_files"
DOCKERFILE_NAME="docker_dns"
DNS_CONTAINER="dns_container"
IMAGE_NAME="dns_image"

# Argüman listesi ve açıklamaları
declare -A ARG_DESCRIPTIONS=(
    ["--dns-port"]="DNS port numarası (varsayılan: 53)"
    ["--host-port"]="Host üzerinde yönlendirilecek port (varsayılan: 53)"
)

# Argümanları parse et
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help
            exit 0
            ;;
        *)
            for arg in "${!ARG_DESCRIPTIONS[@]}"; do
                if [[ $1 == $arg ]]; then
                    case $arg in
                    --dns-port)
                        DNS_PORT="$2"
                        ;;
                    --host-port)
                        HOST_PORT="$2"
                        ;;
                    esac
                    shift 2
                    break
                fi
            done
            if [[ $# -eq 1 ]]; then
                echo "Hata: Bilinmeyen argüman '$1'"
                show_help
                exit 1
            fi
            ;;
        esac
    done
}

# Yardım mesajını göster
show_help() {
    echo "Kullanım: $0 [SEÇENEKLER]"
    echo "Seçenekler:"
    for arg in "${!ARG_DESCRIPTIONS[@]}"; do
        printf "  %-20s %s\n" "$arg" "${ARG_DESCRIPTIONS[$arg]}"
    done
}

# Docker konteynerını çalıştır
run_container() {
    docker run -d --rm --privileged \
        --name $DNS_CONTAINER \
        -p $HOST_PORT:$DNS_PORT/tcp -p $HOST_PORT:$DNS_PORT/udp \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --cap-add=NET_ADMIN \
        $IMAGE_NAME \
        /bin/bash -c "/usr/local/bin/create_dns_server.sh $DNS_PORT && \
                      service named start && \
                      service keepalived start && \
                      while true; do sleep 30; done"
}

# Ana fonksiyon
main() {
    parse_arguments "$@"
    create_image $IMAGE_NAME $DOCKERFILE_PATH $DOCKERFILE_NAME "$SCRIPT_DIR/.."
    run_container
}

# Scripti çalıştır
main "$@"
