#!/bin/bash

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh

# Hata kodları
readonly ERROR_SSH_KEY_GENERATION=1
readonly ERROR_REMOTE_CONNECTION=2
readonly ERROR_KEY_EXCHANGE=3
readonly ERROR_SSH_SERVER_NOT_FOUND=4

# SSH server kontrol fonksiyonu
check_ssh_server() {
    local host="$1"
    local port=22

    if ! nc -z -w5 "$host" "$port" &>/dev/null; then
        echo "Hata: SSH bağlantısı başarısız (Connection refused)"
        echo "Çözüm için:"
        echo "1. Her iki makinede SSH server'ın kurulu olduğundan emin olun:"
        echo "   sudo apt update && sudo apt install openssh-server"
        echo "2. SSH servisinin çalıştığından emin olun:"
        echo "   sudo systemctl start ssh"
        echo "   sudo systemctl enable ssh"
        return $ERROR_SSH_SERVER_NOT_FOUND
    fi
    return 0
}

create_local_ssh_key() {
    local key_path="$1"
    local key_type="ed25519"  # Daha modern ve güvenli bir algoritma
    local key_bits="4096"     # RSA için bit sayısı (ED25519 için gerekli değil)
    local key_comment="glusterfs_$(hostname)_$(date +%Y%m%d)"
    
    if [ ! -f "$key_path" ]; then
        echo "Yerel SSH anahtarı oluşturuluyor..."
        
        # Önce .ssh dizininin izinlerini ayarla
        mkdir -p "$(dirname "$key_path")"
        chmod 700 "$(dirname "$key_path")"
        
        # Eski anahtarları yedekle (varsa)
        if [ -f "$key_path" ]; then
            mv "$key_path" "${key_path}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "${key_path}.pub" "${key_path}.pub.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Anahtar tipine göre oluşturma
        if [ "$key_type" = "ed25519" ]; then
            if ! ssh-keygen -t ed25519 -N "" -C "$key_comment" -f "$key_path" 2>&1; then
                echo "ED25519 anahtar oluşturma başarısız, RSA deneniyor..."
                if ! ssh-keygen -t rsa -b "$key_bits" -N "" -C "$key_comment" -f "$key_path" 2>&1; then
                    echo "Hata detayı: $?"
                    return $ERROR_SSH_KEY_GENERATION
                fi
            fi
        else
            if ! ssh-keygen -t rsa -b "$key_bits" -N "" -C "$key_comment" -f "$key_path" 2>&1; then
                echo "Hata detayı: $?"
                return $ERROR_SSH_KEY_GENERATION
            fi
        fi
        
        # Anahtar dosyası izinlerini ayarla
        chmod 600 "$key_path"
        chmod 644 "${key_path}.pub"
        
        # Anahtarı SSH agent'a ekle
        eval "$(ssh-agent -s)" >/dev/null
        ssh-add "$key_path" 2>/dev/null
    fi
    return 0
}

create_remote_ssh_key() {
    local remote_user="$1"
    local remote_ip="$2"
    local key_type="ed25519"
    local key_bits="4096"
    local key_comment="glusterfs_$(hostname)_remote_$(date +%Y%m%d)"
    
    echo "Uzak sunucuda SSH anahtarı oluşturuluyor..."
    if ! ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no "$remote_user@$remote_ip" "
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        
        if [ ! -f ~/.ssh/${GLUSTERFS_KEY_NAME} ]; then
            # Eski anahtarları yedekle
            if [ -f ~/.ssh/${GLUSTERFS_KEY_NAME} ]; then
                mv ~/.ssh/${GLUSTERFS_KEY_NAME} ~/.ssh/${GLUSTERFS_KEY_NAME}.backup.\$(date +%Y%m%d_%H%M%S)
                mv ~/.ssh/${GLUSTERFS_KEY_NAME}.pub ~/.ssh/${GLUSTERFS_KEY_NAME}.pub.backup.\$(date +%Y%m%d_%H%M%S)
            fi
            
            # Önce ED25519 dene, başarısız olursa RSA kullan
            if ! ssh-keygen -t ed25519 -N \"\" -C \"$key_comment\" -f ~/.ssh/${GLUSTERFS_KEY_NAME} 2>/dev/null; then
                ssh-keygen -t rsa -b $key_bits -N \"\" -C \"$key_comment\" -f ~/.ssh/${GLUSTERFS_KEY_NAME}
            fi
            
            chmod 600 ~/.ssh/${GLUSTERFS_KEY_NAME}
            chmod 644 ~/.ssh/${GLUSTERFS_KEY_NAME}.pub
            
            # Anahtarı SSH agent'a ekle
            eval \"\$(ssh-agent -s)\" >/dev/null
            ssh-add ~/.ssh/${GLUSTERFS_KEY_NAME} 2>/dev/null
        else
            echo 'Anahtar zaten mevcut'
        fi
    "; then
        echo "Hata detayı: $?"
        return 1
    fi
    return 0
}

update_known_hosts() {
    local remote_ip="$1"
    local local_ip="$2"
    
    echo "Known hosts dosyaları güncelleniyor..."
    
    # Yerel makinede uzak sunucunun anahtarını ekle
    ssh-keygen -R "$remote_ip" 2>/dev/null
    if ! ssh-keyscan -H "$remote_ip" >> ~/.ssh/known_hosts 2>&1; then
        echo "Hata detayı: $?"
        return $ERROR_KEY_EXCHANGE
    fi

    # Uzak sunucuda yerel makinenin anahtarını ekle
    if ! ssh "$remote_user@$remote_ip" "
        ssh-keygen -R $local_ip 2>/dev/null
        ssh-keyscan -H $local_ip >> ~/.ssh/known_hosts
    " 2>&1; then
        echo "Hata detayı: $?"
        return $ERROR_KEY_EXCHANGE
    fi

    return 0
}

setup_ssh_keys() {
    local remote_ip
    local remote_user
    local local_ip

    # NODE1 ise (varsayılan true)
    if [ "$IS_NODE_1" = "true" ]; then
        remote_ip="$NODE2_IP"
        remote_user="$NODE2_USER"
        local_ip="$NODE1_IP"
    else
        remote_ip="$NODE1_IP"
        remote_user="$NODE1_USER"
        local_ip="$NODE2_IP"
    fi

    # 1. Önce SSH server kontrolü yap
    if ! check_ssh_server "$remote_ip"; then
        return $ERROR_SSH_SERVER_NOT_FOUND
    fi

    # 2. Yerel anahtar oluştur
    if ! create_local_ssh_key ~/.ssh/$GLUSTERFS_KEY_NAME; then
        echo "Hata: Yerel SSH anahtarı oluşturulamadı"
        return $ERROR_SSH_KEY_GENERATION
    fi

    # 3. Yerel anahtarı uzak sunucuya kopyala (şifre ile bağlantı zorla)
    echo "Yerel anahtar uzak sunucuya kopyalanıyor..."
    if ! cat ~/.ssh/$GLUSTERFS_KEY_NAME.pub | ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no "$remote_user@$remote_ip" '
        mkdir -p ~/.ssh
        cat >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    ' 2>&1; then
        echo "Hata: Yerel anahtar uzak sunucuya kopyalanamadı"
        return $ERROR_KEY_EXCHANGE
    fi

    # 4. Uzak sunucuda anahtar oluştur
    if ! create_remote_ssh_key "$remote_user" "$remote_ip"; then
        echo "Hata: Uzak sunucuda SSH anahtarı oluşturulamadı"
        return $ERROR_REMOTE_CONNECTION
    fi

    # 5. Known hosts güncelle
    if ! update_known_hosts "$remote_ip" "$local_ip"; then
        echo "Hata: Known hosts güncellenemedi"
        return $ERROR_KEY_EXCHANGE
    fi

    # 6. Uzak sunucu anahtarını yerel makineye kopyala
    echo "Uzak sunucu anahtarı yerel makineye kopyalanıyor..."
    if ! ssh "$remote_user@$remote_ip" "cat ~/.ssh/${GLUSTERFS_KEY_NAME}.pub" >> ~/.ssh/authorized_keys 2>&1; then
        echo "Hata: Uzak anahtar yerel makineye kopyalanamadı"
        return $ERROR_KEY_EXCHANGE
    fi
    chmod 600 ~/.ssh/authorized_keys

    echo "SSH anahtar kurulumu başarıyla tamamlandı"
    return 0
}