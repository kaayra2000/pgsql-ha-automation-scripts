#!/bin/bash
# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Parse dosyasını script dizinine göre import etme
source "$SCRIPT_DIR/argument_parser.sh"
# Docker komutunu çalıştırma yetkisini kontrol etme ve ekleme
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
get_log_path() {
    local CONTAINER_NAME=$1
    echo "/var/log/${CONTAINER_NAME}_check.log"
}
# Konteyner ayakta mı scripti oluşturma
create_checkscript() {
    local CONTAINER_NAME=$1
    local LOG_FILE=$(get_log_path "${CONTAINER_NAME}")

    cat << EOF
/bin/bash -c 'echo \"User: \$(/usr/bin/whoami)\" && echo \"Groups: \$(groups)\" && sudo -n /usr/bin/docker inspect -f {{.State.Running}} ${CONTAINER_NAME}' >> /var/log/keepalived_check.log 2>&1
EOF
}


# Keepalived kurulumu
install_keepalived() {
    if ! command -v keepalived &> /dev/null
    then
        echo "Keepalived kuruluyor..."
        sudo apt-get update
        sudo apt-get install -y keepalived
        echo "Keepalived kurulumu tamamlandı."
    else
        echo "Keepalived zaten kurulu."
    fi
}

# Keepalived yapılandırması
configure_keepalived() {
    echo "Keepalived yapılandırılıyor..."
    
    cat << EOF | sudo tee /etc/keepalived/keepalived.conf
global_defs {
    script_user keepalived_script
    enable_script_security
}

# SQL için VRRP yapılandırması
vrrp_script check_sql {
    script "$(create_checkscript $SQL_CONTAINER)"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance VI_SQL {
    state $STATE
    interface $INTERFACE
    virtual_router_id 52
    priority $PRIORITY
    advert_int 1
    virtual_ipaddress {
        $SQL_VIRTUAL_IP
    }
    track_script {
        check_sql
    }
}

# DNS için VRRP yapılandırması
vrrp_script check_dns {
    script "$(create_checkscript $DNS_CONTAINER)"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance VI_DNS {
    state $STATE
    interface $INTERFACE
    virtual_router_id 53
    priority $PRIORITY
    advert_int 1
    virtual_ipaddress {
        $DNS_VIRTUAL_IP
    }
    track_script {
        check_dns
    }
}
EOF

    echo "Keepalived yapılandırması tamamlandı."
}

# Keepalived servisini başlatma ve etkinleştirme
start_keepalived() {
    if systemctl is-active --quiet keepalived; then
        echo "Keepalived servisi zaten çalışıyor. Yeniden başlatılıyor..."
        sudo systemctl restart keepalived
    else
        echo "Keepalived servisi başlatılıyor..."
        sudo systemctl start keepalived
    fi
    
    if ! systemctl is-enabled --quiet keepalived; then
        echo "Keepalived servisi etkinleştiriliyor..."
        sudo systemctl enable keepalived
    else
        echo "Keepalived servisi zaten etkinleştirilmiş."
    fi
    
    echo "Keepalived servisi başlatıldı/yeniden başlatıldı ve etkinleştirildi."
}

# ilgili kontrol scriptinin log dosyasını oluştur
setup_container_log() {
    local CONTAINER_NAME=$1
    local LOG_FILE=$(get_log_path "${CONTAINER_NAME}")
    
    echo "Log dosyası kontrolü yapılıyor: ${LOG_FILE}"
    
    # Log dosyasının varlığını kontrol et
    if [ ! -f "${LOG_FILE}" ]; then
        echo "Log dosyası bulunamadı. Oluşturuluyor..."
        sudo touch "${LOG_FILE}"
        sudo chown keepalived_script:keepalived_script "${LOG_FILE}"
        sudo chmod 644 "${LOG_FILE}"
        echo "Log dosyası oluşturuldu: ${LOG_FILE}"
    else
        echo "Log dosyası mevcut. İzinler kontrol ediliyor..."
        
        # Dosya sahipliğini kontrol et
        OWNER=$(stat -c '%U:%G' "${LOG_FILE}")
        if [ "${OWNER}" != "keepalived_script:keepalived_script" ]; then
            echo "Dosya sahipliği düzeltiliyor..."
            sudo chown keepalived_script:keepalived_script "${LOG_FILE}"
        fi
        
        # Dosya izinlerini kontrol et
        PERMS=$(stat -c '%a' "${LOG_FILE}")
        if [ "${PERMS}" != "644" ]; then
            echo "Dosya izinleri düzeltiliyor..."
            sudo chmod 644 "${LOG_FILE}"
        fi
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

# Parse fonksiyonunu çağırma ve sonuçları alma
parse_arguments "$@"
create_keepalived_user
setup_container_log $SQL_CONTAINER
setup_container_log $DNS_CONTAINER
configure_sudo_access
check_and_add_docker_permissions
install_keepalived
configure_keepalived
start_keepalived

echo "Keepalived kurulumu ve yapılandırması tamamlandı."
