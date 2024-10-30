#!/bin/bash

# keepalived_script kullanıcısına docker yetkisi verme
check_and_add_docker_permissions() {
    if ! groups keepalived_script | grep -q docker; then
        echo "keepalived_script kullanıcısına docker grubuna ekleniyor..."
        sudo usermod -aG docker keepalived_script
        echo "keepalived_script kullanıcısı docker grubuna eklendi."
    else
        echo "keepalived_script kullanıcısı zaten docker grubunda."
    fi
}

# keepalived_script kullanıcısını oluşturma
create_keepalived_user() {
    if ! id "keepalived_script" &>/dev/null; then
        echo "keepalived_script kullanıcısı oluşturuluyor..."
        sudo useradd -r -s /sbin/nologin keepalived_script
        echo "keepalived_script kullanıcısı oluşturuldu."
    else
        echo "keepalived_script kullanıcısı zaten mevcut."
    fi
}

# keepalived_script kullanıcısına sudo yetkisi verme
configure_sudo_access() {
    echo "Sudo erişimi yapılandırılıyor..."

    # Sudoers.d dizininin varlığını kontrol et
    if [ ! -d "/etc/sudoers.d" ]; then
        sudo mkdir -p /etc/sudoers.d
        sudo chmod 750 /etc/sudoers.d
    fi

    # Keepalived için sudo kuralını oluştur
    sudo bash -c 'cat > /etc/sudoers.d/keepalived << EOF
keepalived_script ALL=(ALL) NOPASSWD: /usr/bin/docker
EOF'

    # Dosya izinlerini ayarla
    sudo chmod 440 /etc/sudoers.d/keepalived

    # Syntax kontrolü yap
    if sudo visudo -c; then
        echo "Sudo erişimi başarıyla yapılandırıldı."
    else
        echo "Hata: Sudo yapılandırması başarısız oldu!"
        sudo rm -f /etc/sudoers.d/keepalived
        return 1
    fi
}
