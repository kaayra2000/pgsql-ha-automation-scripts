#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/set_swarm_node_variables.sh
source $SCRIPT_DIR/../argument_parser.sh
# Paketleri güncelle ve Docker'ı kur
update_and_install_docker() {
    # Docker kurulu mu kontrol et
    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker bulunamadı, kuruluyor..."
        # Paket listelerini güncelle
        sudo apt-get update || return 1
        # Gerekli paketleri kur
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common || return 1
        # Docker'ın resmi GPG anahtarını ekle
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || return 1
        # Docker deposunu ekle
        sudo add-apt-repository \
           "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
           $(lsb_release -cs) \
           stable" || return 1
        # Paket listelerini tekrar güncelle
        sudo apt-get update || return 1
        # Docker Engine'i kur
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io || return 1
        echo "Docker başarıyla kuruldu."
    else
        echo "Docker zaten kurulu."
    fi
    return 0
}

# Docker servisini başlat ve etkinleştir
enable_docker() {
    # Docker servisi çalışıyor mu kontrol et
    if ! sudo systemctl is-active --quiet docker; then
        echo "Docker servisi başlatılıyor..."
        sudo systemctl start docker || return 1
    else
        echo "Docker servisi zaten çalışıyor."
    fi
    # Docker servisi etkin mi kontrol et
    if ! sudo systemctl is-enabled --quiet docker; then
        echo "Docker servisi sistem başlangıcında başlatılmak üzere etkinleştiriliyor..."
        sudo systemctl enable docker || return 1
    else
        echo "Docker servisi zaten etkinleştirilmiş."
    fi
    return 0
}

# Kullanıcıyı docker grubuna ekle
add_user_to_docker_group() {
    # Kullanıcı docker grubunda mı kontrol et
    if ! groups $USER | grep -q '\bdocker\b'; then
        echo "Kullanıcı '$USER' docker grubuna ekleniyor..."
        sudo usermod -aG docker $USER || return 1
        # Değişikliklerin etkili olması için yeni grup oturumu başlat
        newgrp docker || return 1
    else
        echo "Kullanıcı '$USER' zaten docker grubunda."
    fi
    return 0
}

# Docker Swarm'ı başlat
initialize_docker_swarm_manager() {
    # Docker Swarm zaten başlatılmış mı kontrol et
    if ! docker info | grep -q 'Swarm: active'; then
        echo "Docker Swarm başlatılıyor..."
        docker swarm init --advertise-addr $CURRENT_NODE_IP || return 1
        echo "Docker Swarm başarıyla başlatıldı."
    else
        echo "Docker Swarm manager zaten ilklendirilmiş."
    fi
    return 0
}

write_swarm_worker_token() {
    # Swarm Worker Token'ını al
    local SWARM_WORKER_TOKEN
    SWARM_WORKER_TOKEN=$(docker swarm join-token -q worker)
    if [ -z "$SWARM_WORKER_TOKEN" ]; then
        echo "Hata: Swarm Worker Token alınamadı."
        return 1
    fi

    # ARGUMENT_CFG_FILE değişkeninin tanımlı olduğundan emin olun
    if [ -z "$ARGUMENT_CFG_FILE" ]; then
        echo "Hata: ARGUMENT_CFG_FILE değişkeni tanımlı değil."
        return 1
    fi

    # Token'ı arguments.cfg dosyasına ekle veya güncelle
    update_config_file "DOCKER_SWARM_WORKER_TOKEN" "$ARGUMENT_CFG_FILE" "$SWARM_WORKER_TOKEN"

    # İşlemin başarısını kontrol et
    if [ $? -ne 0 ]; then
        echo "Hata: Worker Token arguments.cfg dosyasına yazılamadı."
        return 1
    fi

    echo "Swarm Worker Token başarıyla arguments.cfg dosyasına yazıldı."
    return 0
}

# manager olan Docker Swarm cluster'ına katıl
join_swarm_as_worker() {
    DOCKER_SWARM_JOIN_PORT=2377
    # DOCKER_SWARM_WORKER_TOKEN tanımlı mı kontrol et
    if [ -z "$DOCKER_SWARM_WORKER_TOKEN" ]; then
        echo "Hata: DOCKER_SWARM_WORKER_TOKEN tanımlı değil."
        return 1
    fi

    # NODE1_IP tanımlı mı kontrol et
    if [ -z "$NODE1_IP" ]; then
        echo "Hata: NODE1_IP tanımlı değil."
        return 1
    fi

    echo "Worker düğüm Swarm cluster'ına katılıyor..."

    # Swarm'a katılma komutu
    sudo docker swarm join --token "$DOCKER_SWARM_WORKER_TOKEN" "$NODE1_IP:$DOCKER_SWARM_JOIN_PORT"
    if [ $? -ne 0 ]; then
        echo "Hata: Swarm cluster'a katılım başarısız oldu."
        return 1
    fi

    echo "Başarıyla Swarm cluster'ına katıldınız."
    return 0
}