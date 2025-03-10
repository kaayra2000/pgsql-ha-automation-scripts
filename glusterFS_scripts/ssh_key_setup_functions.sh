#!/bin/bash


# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/set_node_variables.sh

# Hata kodları
readonly ERROR_SSH_KEY_GENERATION=1
readonly ERROR_REMOTE_CONNECTION=2
readonly ERROR_KEY_EXCHANGE=3
readonly ERROR_SSH_SERVER_NOT_FOUND=4
readonly ERROR_UPDATE_SSH_CONFIG=5
readonly ERROR_UPDATE_KNOWN_HOSTS=6

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
    local key_path="$1"  # SSH anahtarının oluşturulacağı dosya yolu
    local key_type="ed25519"  # Varsayılan anahtar türü
    local key_comment="glusterfs_$(hostname)_$(date +%Y%m%d)"  # Anahtar açıklaması
    local key_dir
    key_dir=$(dirname "$key_path")  # Anahtarın bulunduğu dizin

    echo "Yerel SSH anahtarı oluşturuluyor..."
    # Anahtar dosyasının mevcut olup olmadığını kontrol et
    if [ -f "$key_path" ]; then
        echo "Anahtar dosyası zaten mevcut. Herhangi bir yerel anahtar oluşturma işlemi yapılmadı."
        return 0
    fi
    # .ssh dizinini kontrol et ve oluştur
    if [ ! -d "$key_dir" ]; then
        mkdir -p "$key_dir"
        chmod 700 "$key_dir"
    fi

    # Anahtar oluşturma işlemi
    if ! ssh-keygen -t "$key_type" -N "" -C "$key_comment" -f "$key_path"; then
        echo "Hata: $key_type türünde SSH anahtarı oluşturulamadı. Lütfen sistem rastgelelik kaynağını kontrol edin."
        return 1
    fi

    echo "SSH anahtarı başarıyla oluşturuldu: $key_path"
    # Anahtarı SSH agent'a ekle
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$key_path" 2>/dev/null
    return 0
}

update_local_ssh_config() {
    local local_ip="$1"
    local remote_user="$2"
    local remote_ip="$3"
    local ssh_dir="$HOME/.ssh"
    local ssh_config_file="$ssh_dir/config"
    local identity_file="$ssh_dir/$GLUSTERFS_KEY_NAME"

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

    return 0
}

update_remote_ssh_config() {
    local local_ip="$1"
    local remote_user="$2"
    local remote_ip="$3"
    local local_user="$4"

    # Uzak sunucuda dinamik olarak genişletilecek yollar
    local remote_ssh_dir="\$HOME/.ssh"
    local remote_ssh_config_file="\$HOME/.ssh/config"

    # Uzak sunucuda .ssh dizinini oluştur (eğer yoksa)
    ssh "$remote_user@$remote_ip" "if [ ! -d \"$remote_ssh_dir\" ]; then mkdir -p \"$remote_ssh_dir\" && chmod 700 \"$remote_ssh_dir\"; fi" || return 1

    # Uzak sunucuda SSH config dosyasını oluştur (eğer yoksa)
    ssh "$remote_user@$remote_ip" "if [ ! -f \"$remote_ssh_config_file\" ]; then touch \"$remote_ssh_config_file\" && chmod 600 \"$remote_ssh_config_file\"; fi" || return 1

    # Uzak sunucuda yapılandırmayı kontrol et ve ekle
    ssh "$remote_user@$remote_ip" "if ! grep -q 'Host $local_ip' \"$remote_ssh_config_file\"; then
        echo 'Uzak SSH yapılandırması ekleniyor...'
        cat <<EOF >> \"$remote_ssh_config_file\"

Host $local_ip
    User $local_user
    IdentityFile \$HOME/.ssh/glusterfs_key
    IdentitiesOnly yes
EOF
        echo 'Uzak SSH yapılandırması tamamlandı: $local_ip'
    else
        echo 'Uzak SSH yapılandırması zaten mevcut: $local_ip'
    fi" || return 1

    return 0
}

create_remote_ssh_key() {
    local remote_user="$1"
    local remote_ip="$2"
    local key_path="$3"
    local key_type="ed25519"
    local key_comment="glusterfs_$(hostname)_remote_$(date +%Y%m%d)"
    local key_dir=(dirname "$key_path")

    echo "Uzak sunucuda SSH anahtarı oluşturuluyor..."

    # Uzak sunucuda SSH anahtarı oluşturma işlemi
    if ! ssh "$remote_user@$remote_ip" "
        # .ssh dizinini kontrol et ve oluştur
        if [ ! -d $key_dir ]; then
            mkdir -p $key_dir
            chmod 700 $key_dir
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

# Yerel anahtarı uzak sunucuya kopyalayan fonksiyon
copy_ssh_key_to_remote() {
    local key_path="$1"
    local remote_user="$2"
    local remote_ip="$3"

    echo "Yerel anahtar uzak sunucuya kopyalanıyor..."
    if ! cat "$key_path.pub" | ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no "$remote_user@$remote_ip" '
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
    ' 2>&1; then
        echo "Hata: Yerel anahtar uzak sunucuya kopyalanamadı"
        return $ERROR_KEY_EXCHANGE
    fi
    echo "Yerel anahtar uzak sunucuya başarıyla kopyalandı."
    return 0
}

# SSH anahtarlarını kuran ana fonksiyon
setup_ssh_keys() {
    local remote_ip
    local remote_user
    local local_ip
    local local_user

    # NODE1 kontrolü
    set_node_variables

    # SSH server kontrolü yap mevcut değilse hata döndür
    if ! check_ssh_server "$remote_ip"; then
        return $ERROR_SSH_SERVER_NOT_FOUND
    fi

    # şifresiz SSH bağlantısı için anahtar oluştur
    if ! create_local_ssh_key ~/.ssh/$GLUSTERFS_KEY_NAME; then
        echo "Hata: Yerel SSH anahtarı oluşturulamadı"
        return $ERROR_SSH_KEY_GENERATION
    fi

    echo "Yerel SSH yapılandırması güncelleniyor..."

    # Varsayılan olarak oluşturulan anahtarla bağlanmak için yerel SSH yapılandırmasını güncelle
    if ! update_local_ssh_config "$local_ip" "$remote_user" "$remote_ip"; then
        echo "Hata: Yerel SSH yapılandırması güncellenemedi"
        return $ERROR_UPDATE_SSH_CONFIG
    fi

    # Şifresiz SSH bağlantısı için anahtarı uzak sunucuya kopyala
    if ! copy_ssh_key_to_remote ~/.ssh/$GLUSTERFS_KEY_NAME "$remote_user" "$remote_ip"; then
        return $ERROR_KEY_EXCHANGE
    fi

    echo "Uzak SSH yapılandırması güncelleniyor..."
    # Varsayılan olarak oluşturulan anahtarla bağlanmak için uzak SSH yapılandırmasını güncelle
    if ! update_remote_ssh_config "$local_ip" "$remote_user" "$remote_ip" "$local_user"; then
        echo "Hata: Uzak SSH yapılandırması güncellenemedi"
        return $ERROR_UPDATE_SSH_CONFIG
    fi

    # Şifresiz SSH bağlantısı için uzak sunucuda anahtar oluştur
    if ! create_remote_ssh_key "$remote_user" "$remote_ip" "~/.ssh/${GLUSTERFS_KEY_NAME}"; then
        echo "Hata: Uzak sunucuda SSH anahtarı oluşturulamadı"
        return $ERROR_REMOTE_CONNECTION
    fi

    # Tekrar tekrar sorulmaması için known_hosts dosyasını güncelle
    if ! update_known_hosts "$remote_ip" "$local_ip"; then
        echo "Hata: Known hosts güncellenemedi"
        return $ERROR_UPDATE_KNOWN_HOSTS
    fi

    # Şifresiz SSH bağlantısı için anahtarı yerel makineye kopyala
    echo "Uzak sunucu anahtarı yerel makineye kopyalanıyor..."
    if ! ssh "$remote_user@$remote_ip" "cat ~/.ssh/${GLUSTERFS_KEY_NAME}.pub" >> ~/.ssh/authorized_keys 2>&1; then
        echo "Hata: Uzak anahtar yerel makineye kopyalanamadı"
        return $ERROR_KEY_EXCHANGE
    fi

    echo "SSH anahtar kurulumu başarıyla tamamlandı"
    return 0
}