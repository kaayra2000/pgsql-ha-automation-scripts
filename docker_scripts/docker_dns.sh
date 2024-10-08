#!/bin/bash

# Parametreleri tanımla
INTERFACE="eth0"
VIRTUAL_IP="10.207.8.100"
PRIORITY="100"
DNS_PORT="53"
DOCKER_FILES="../docker_files"
CONTAINER_IP="10.207.8.15"  # Ağ alt ağıyla uyumlu hale getirildi
DOCKERFILE_NAME="docker_dns"
IMAGE_NAME="dns_image"  # Özel bir imaj adı kullanıldı
NETWORK_NAME="dns_network"
NETWORK_SUBNET="10.207.8.0/24"

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

# Ağ oluştur
create_network

# Docker imajını oluştur
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

# Docker konteynerını çalıştır ve scriptleri execute et
docker run -d --rm --privileged \
    --name dns_container \
    --network $NETWORK_NAME \
    --ip $CONTAINER_IP \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --cap-add=NET_ADMIN \
    $IMAGE_NAME \
    /bin/bash -c "/usr/local/bin/create_keepalived.sh $INTERFACE $VIRTUAL_IP $PRIORITY && /usr/local/bin/create_dns_server.sh $DNS_PORT && tail -f /dev/null"
