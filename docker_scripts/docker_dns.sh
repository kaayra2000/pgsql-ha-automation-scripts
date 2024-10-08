#!/bin/bash

# Varsayılan değerler
INTERFACE="eth0"
KEEPALIVED_IP="10.207.80.100"
PRIORITY="100"
DNS_PORT="53"
CONTAINER_IP="10.207.80.15"
NETWORK_SUBNET="10.207.80.0/24"

# Sabit değerler
DOCKER_FILES="../docker_files"
DOCKERFILE_NAME="docker_dns"
IMAGE_NAME="dns_image"
NETWORK_NAME="dns_network"

# Argüman listesi ve açıklamaları
declare -A ARG_DESCRIPTIONS=(
    ["--interface"]="Ağ arayüzü (varsayılan: eth0)"
    ["--keepalived-ip"]="Keepalived sanal IP adresi (varsayılan: 10.207.80.100)"
    ["--priority"]="Keepalived önceliği (varsayılan: 100)"
    ["--dns-port"]="DNS port numarası (varsayılan: 53)"
    ["--container-ip"]="Konteyner IP adresi (varsayılan: 10.207.80.15)"
    ["--network-subnet"]="Ağ alt ağı (varsayılan: 10.207.8.0/24)"
)

# Argümanları parse et
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                for arg in "${!ARG_DESCRIPTIONS[@]}"; do
                    if [[ $1 == $arg ]]; then
                        case $arg in
                            --interface)
                                INTERFACE="$2"
                                ;;
                            --keepalived-ip)
                                KEEPALIVED_IP="$2"
                                ;;
                            --priority)
                                PRIORITY="$2"
                                ;;
                            --dns-port)
                                DNS_PORT="$2"
                                ;;
                            --container-ip)
                                CONTAINER_IP="$2"
                                ;;
                            --network-subnet)
                                NETWORK_SUBNET="$2"
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


# Ağ kontrolü ve oluşturma fonksiyonu
create_network() {
    if docker network inspect $NETWORK_NAME >/dev/null 2>&1; then
        read -p "Ağ '$NETWORK_NAME' zaten mevcut. Silip yeniden oluşturmak ister misiniz? (e/h): " response
        if [[ "$response" =~ ^[Ee]$ ]]; then
            docker network rm $NETWORK_NAME
            docker network create --subnet=$NETWORK_SUBNET $NETWORK_NAME
            echo "Ağ yeniden oluşturuldu."
        else
            echo "Mevcut ağ kullanılacak."
        fi
    else
        docker network create --subnet=$NETWORK_SUBNET $NETWORK_NAME
        echo "Yeni ağ oluşturuldu."
    fi
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
        --network $NETWORK_NAME \
        --ip $CONTAINER_IP \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --cap-add=NET_ADMIN \
        $IMAGE_NAME \
        /bin/bash -c "/usr/local/bin/create_keepalived.sh $INTERFACE $KEEPALIVED_IP $PRIORITY && \
                      /usr/local/bin/create_dns_server.sh $DNS_PORT && \
                      service named start && \
                      service keepalived start && \
                      while true; do sleep 30; done"
}

# Ana fonksiyon
main() {
    parse_arguments "$@"
    create_network
    create_image
    run_container
}

# Scripti çalıştır
main "$@"
