#!/bin/bash

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
initialize_docker_swarm() {
    # Docker Swarm zaten başlatılmış mı kontrol et
    if ! docker info | grep -q 'Swarm: active'; then
        echo "Docker Swarm başlatılıyor..."
        docker swarm init || return 1
        echo "Docker Swarm başarıyla başlatıldı."
    else
        echo "Docker Swarm zaten başlatılmış."
    fi
    return 0
}