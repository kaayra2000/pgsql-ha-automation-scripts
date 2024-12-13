#!/bin/bash

# $KEEPALIVED_SCRIPT_USER kullanıcısına docker yetkisi verme
check_and_add_docker_permissions() {
    if ! groups $KEEPALIVED_SCRIPT_USER | grep -q docker; then
        echo "$KEEPALIVED_SCRIPT_USER kullanıcısına docker grubuna ekleniyor..."
        sudo usermod -aG docker $KEEPALIVED_SCRIPT_USER
        echo "$KEEPALIVED_SCRIPT_USER kullanıcısı docker grubuna eklendi."
    else
        echo "$KEEPALIVED_SCRIPT_USER kullanıcısı zaten docker grubunda."
    fi
}

# $KEEPALIVED_SCRIPT_USER kullanıcısını oluşturma
create_keepalived_user() {
    if ! id "$KEEPALIVED_SCRIPT_USER" &>/dev/null; then
        echo "$KEEPALIVED_SCRIPT_USER kullanıcısı oluşturuluyor..."
        sudo useradd -r -s /sbin/nologin $KEEPALIVED_SCRIPT_USER
        echo "$KEEPALIVED_SCRIPT_USER kullanıcısı oluşturuldu."
    else
        echo "$KEEPALIVED_SCRIPT_USER kullanıcısı zaten mevcut."
    fi
}

# $KEEPALIVED_SCRIPT_USER kullanıcısına sudo yetkisi verme
configure_sudo_access() {
    echo "Sudo erişimi yapılandırılıyor..."

    # Sudoers.d dizininin varlığını kontrol et
    if [ ! -d "/etc/sudoers.d" ]; then
        sudo mkdir -p /etc/sudoers.d
        sudo chmod 750 /etc/sudoers.d
    fi

    # Keepalived için sudo kuralını oluştur
    sudo bash -c "cat > /etc/sudoers.d/keepalived << EOF
$KEEPALIVED_SCRIPT_USER ALL=(ALL) NOPASSWD: /usr/bin/docker
EOF"

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
