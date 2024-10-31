#!/bin/bash

# Varsayılan değerler
DNS_PORT="53"
HOST_PORT="53"

# Sabit değerler
DOCKER_FILES="../docker_files"
DOCKERFILE_NAME="docker_dns"
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

# Docker imajını oluştur
create_image() {
    if docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
        read -p "İmaj '$IMAGE_NAME' zaten mevcut. Yeniden oluşturmak ister misiniz? (e/h): " response
        if [[ "$response" =~ ^[Ee]$ ]]; then
            docker build -t $IMAGE_NAME -f $DOCKER_FILES/$DOCKERFILE_NAME ..
            echo "İmaj yeniden oluşturuldu."
        else
            echo "Mevcut imaj kullanılacak."
        fi
    else
        docker build -t $IMAGE_NAME -f $DOCKER_FILES/$DOCKERFILE_NAME ..
        echo "Yeni imaj oluşturuldu."
    fi
}

# Docker konteynerını çalıştır
run_container() {
    docker run -d --rm --privileged \
        --name dns_container \
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
    create_image
    run_container
}

# Scripti çalıştır
main "$@"
