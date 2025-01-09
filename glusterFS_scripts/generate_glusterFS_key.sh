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

update_local_ssh_config() {
    local local_ip="$1"
    local remote_user="$2"
    local remote_ip="$3"
    local ssh_config_file="$HOME/.ssh/config"
    local identity_file="$HOME/.ssh/glusterfs_key"

    # .ssh dizini yoksa oluştur
    if [ ! -d "$HOME/.ssh" ]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
    fi

    # SSH config dosyası yoksa oluştur
    if [ ! -f "$ssh_config_file" ]; then
        touch "$ssh_config_file"
        chmod 600 "$ssh_config_file"
    fi

    # Host yapılandırması kontrol ediliyor
    if ! grep -q "Host $remote_ip" "$ssh_config_file"; then
        echo "Yerel SSH yapılandırması ekleniyor..."
        cat <<EOF >> "$ssh_config_file"

Host $remote_ip
    User $remote_user
    IdentityFile $identity_file
    IdentitiesOnly yes
EOF
        echo "Yerel SSH yapılandırması tamamlandı: $remote_ip"
    else
        echo "Yerel SSH yapılandırması zaten mevcut: $remote_ip"
    fi
}

update_remote_ssh_config() {
    local local_ip="$1"
    local remote_user="$2"
    local remote_ip="$3"
    local local_user="$4"
    local remote_ssh_config_file="/home/$remote_user/.ssh/config"

    # Uzak sunucuda .ssh dizinini oluştur
    ssh "$remote_user@$remote_ip" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

    # Uzak sunucuda SSH config dosyasını oluştur
    ssh "$remote_user@$remote_ip" "if [ ! -f $remote_ssh_config_file ]; then touch $remote_ssh_config_file && chmod 600 $remote_ssh_config_file; fi"

    # Uzak sunucuda yapılandırmayı kontrol et ve ekle
    ssh "$remote_user@$remote_ip" "if ! grep -q 'Host $local_ip' $remote_ssh_config_file; then
        echo 'Uzak SSH yapılandırması ekleniyor...'
        cat <<EOF >> $remote_ssh_config_file

Host $local_ip
    User $local_user
    IdentityFile ~/.ssh/glusterfs_key
    IdentitiesOnly yes
EOF
        echo 'Uzak SSH yapılandırması tamamlandı: $local_ip'
    else
        echo 'Uzak SSH yapılandırması zaten mevcut: $local_ip'
    fi"
}

create_remote_ssh_key() {
    local remote_user="$1"
    local remote_ip="$2"
    local key_type="ed25519"
    local key_comment="glusterfs_$(hostname)_remote_$(date +%Y%m%d)"
    local ssh_dir="~/.ssh"
    local key_path="$ssh_dir/${GLUSTERFS_KEY_NAME}"

    echo "Uzak sunucuda SSH anahtarı oluşturuluyor..."

    # Uzak sunucuda SSH anahtarı oluşturma işlemi
    if ! ssh "$remote_user@$remote_ip" "
        # .ssh dizinini kontrol et ve oluştur
        if [ ! -d $ssh_dir ]; then
            mkdir -p $ssh_dir
            chmod 700 $ssh_dir
        fi

        # Anahtar dosyası mevcutsa yedekle
        if [ -f $key_path ]; then
            mv $key_path ${key_path}.backup.\$(date +%Y%m%d_%H%M%S)
            mv ${key_path}.pub ${key_path}.pub.backup.\$(date +%Y%m%d_%H%M%S)
        fi

        # Anahtar oluşturma işlemi
        if ! ssh-keygen -t $key_type -N \"\" -C \"$key_comment\" -f $key_path; then
            echo 'Hata: SSH anahtarı oluşturulamadı. Lütfen sistem rastgelelik kaynağını kontrol edin.'
            exit 1
        fi
        # Anahtarı SSH agent'a ekle
        if command -v ssh-agent >/dev/null; then
            eval \"\$(ssh-agent -s)\" >/dev/null
            ssh-add $key_path 2>/dev/null
        else
            echo 'SSH agent bulunamadı, anahtar eklenemedi.'
        fi
    "; then
        echo "Hata: Uzak sunucuda SSH anahtarı oluşturulamadı."
        return 1
    fi

    echo "SSH anahtarı başarıyla oluşturuldu."
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
    local local_user

    # NODE1 ise (varsayılan true)
    if [ "$IS_NODE_1" = "true" ]; then
        remote_ip="$NODE2_IP"
        remote_user="$NODE2_USER"
        local_ip="$NODE1_IP"
        local_user="$NODE1_USER"
    else
        remote_ip="$NODE1_IP"
        remote_user="$NODE1_USER"
        local_ip="$NODE2_IP"
        local_user="$NODE2_USER"
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

    echo "Yerel SSH yapılandırması güncelleniyor..."
    update_local_ssh_config "$local_ip" "$remote_user" "$remote_ip"

    # 3. Yerel anahtarı uzak sunucuya kopyala (şifre ile bağlantı zorla)
    echo "Yerel anahtar uzak sunucuya kopyalanıyor..."
    if ! cat ~/.ssh/$GLUSTERFS_KEY_NAME.pub | ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no "$remote_user@$remote_ip" '
        mkdir -p ~/.ssh
        cat >> ~/.ssh/authorized_keys
    ' 2>&1; then
        echo "Hata: Yerel anahtar uzak sunucuya kopyalanamadı"
        return $ERROR_KEY_EXCHANGE
    fi

    echo "Uzak SSH yapılandırması güncelleniyor..."
    update_remote_ssh_config "$local_ip" "$remote_user" "$remote_ip" "$local_user"

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

    echo "SSH anahtar kurulumu başarıyla tamamlandı"
    return 0
}