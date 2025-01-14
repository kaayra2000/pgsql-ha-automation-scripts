#!/bin/bash

install_glusterfs() {
    echo "Yerel makinede GlusterFS kurulumu kontrol ediliyor..."
    local INSTALL_GLUSTERFS_PACKAGES="glusterfs-server glusterfs-client"
    # 1) GlusterFS kurulu mu?
    if dpkg -l $INSTALL_GLUSTERFS_PACKAGES &>/dev/null; then
        echo "GlusterFS zaten kurulu. Kurulum aşaması atlanıyor."
    else
        echo "GlusterFS kurulumu yapılıyor..."
        sudo apt-get update -y
        sudo apt-get install -y $INSTALL_GLUSTERFS_PACKAGES
        echo "GlusterFS kurulumu tamamlandı."
    fi

    # 2) Servis ayakta mı?
    if ! systemctl is-active --quiet glusterd; then
        echo "GlusterFS servisi başlatılıyor..."
        sudo systemctl start glusterd
    else
        echo "GlusterFS servisi zaten çalışıyor."
    fi

    # 3) Servis enable mı?
    if ! systemctl is-enabled --quiet glusterd; then
        echo "GlusterFS servisi enable ediliyor..."
        sudo systemctl enable glusterd
    else
        echo "GlusterFS servisi zaten enable durumunda."
    fi

    echo "Yerel GlusterFS işlemleri tamamlandı."
}
# GlusterFS Trusted Storage Pool'a cihaz ekleme fonksiyonu
add_to_trusted_storage_pool() {
    local remote_ip="$1"  # Uzak cihazın IP adresi

    # Gerekli kontrol
    if [[ -z "$remote_ip" ]]; then
        echo "Hata: Uzak cihazın IP adresi belirtilmedi."
        echo "Kullanım: add_to_trusted_storage_pool <remote_ip>"
        return 1
    fi

    # GlusterFS servisini kontrol et ve başlat
    if ! systemctl is-active --quiet glusterd; then
        echo "GlusterFS servisi başlatılıyor..."
        sudo systemctl start glusterd
        if ! systemctl is-active --quiet glusterd; then
            echo "Hata: GlusterFS servisi başlatılamadı. Lütfen servisi manuel olarak kontrol edin."
            return 1
        fi
    fi

    # Uzak cihazı trusted storage pool'a ekle
    echo "Uzak cihaz trusted storage pool'a ekleniyor: $remote_ip"
    sudo gluster peer probe "$remote_ip"
    if [[ $? -ne 0 ]]; then
        echo "Hata: Uzak cihaz trusted storage pool'a eklenemedi. Lütfen logları kontrol edin. Eğer peer probe: failed: \
<komşu ip adresi> is either already part of another cluster or having volumes configured hatası alıyorsanız \
sudo gluster peer detach <komşu ip adresi> komutu işinizi görecektir."
        return 1
    fi

    # Peer 'Peer in Cluster' durumuna geçene kadar bekle
    echo "Peer 'Peer in Cluster' durumuna geçene kadar bekleniyor..."
    local attempt=0
    while true; do
        # Peer durumunu kontrol et
        peer_state=$(sudo gluster peer status | awk -v ip="$remote_ip" '
            $0 ~ ip {found=1} 
            found && /State:/ {print substr($0, index($0, $2)); exit}
        ')
        if [[ "$peer_state" == *"Peer in Cluster"* || "$peer_state" == *"Connected"* ]]; then
            echo -ne "\rPeer durumu uygun: $peer_state. İşlem tamamlandı.                     \n"
            break
        fi


        # Durumu terminalde aynı satırda göster
        echo -ne "\rPeer durumu: $peer_state. Bekleniyor... (Deneme: $((attempt + 1)))"
        sleep 4
        ((attempt++))
    done

    # Trusted storage pool'u listele
    echo "Trusted storage pool durumu:"
    sudo gluster pool list

    echo "Uzak cihaz başarıyla trusted storage pool'a eklendi."
    return 0
}

# Kullanıcı ve grup sahipliğini kontrol edip gerekirse değiştirir
change_ownership_if_needed() {
    local user="$1"
    local group="$2"
    local path="$3"

    # Kullanıcı mevcut mu kontrol et
    if ! id "$user" &>/dev/null; then
        echo "Hata: Kullanıcı '$user' mevcut değil. Lütfen geçerli bir kullanıcı adı girin."
        return 1
    fi

    # Grup mevcut mu kontrol et
    if ! getent group "$group" &>/dev/null; then
        echo "Hata: Grup '$group' mevcut değil. Lütfen geçerli bir grup adı girin."
        return 1
    fi

    # Mevcut sahibi kontrol et
    current_owner=$(stat -c '%U' "$path")
    if [[ "$current_owner" != "$user" ]]; then
        echo "$path dizininin sahibi $current_owner. Sahiplik $user:$group olarak değiştiriliyor..."
        sudo chown "$user:$group" "$path"
    else
        echo "$path dizininin sahibi zaten $user:$group."
    fi
}

# İzinleri kontrol edip gerekirse değiştirir
change_permissions_if_needed() {
    local permissions="$1"
    local path="$2"

    # Mevcut izinleri kontrol et
    current_permissions=$(stat -c '%a' "$path")
    if [[ "$current_permissions" != "$permissions" ]]; then
        echo "$path dizininin izinleri $permissions olarak değiştiriliyor..."
        sudo chmod "$permissions" "$path"
    else
        echo "$path dizininin izinleri zaten $permissions."
    fi
    return 0
}

check_and_prepare_brick_path() {
    local brick_path="$1"
    local gluster_user="gluster"
    local gluster_group="gluster"

    if [[ -z "$brick_path" ]]; then
        echo "Hata: Brick dizini belirtilmedi."
        return 1
    fi

    if [[ -d "$brick_path" ]]; then
        echo "$brick_path dizini zaten mevcut."

        # Eğer dizin boş değilse hata ver
        if [[ "$(ls -A "$brick_path")" ]]; then
            echo "Hata: $brick_path dizini dolu. Lütfen boş bir dizin belirtin ya da dizini temizleyin."
            return 1
        fi
    else
        echo "$brick_path dizini oluşturuluyor..."
        sudo mkdir -p "$brick_path"
        echo "$brick_path dizini başarıyla oluşturuldu."
    fi
    if ! change_ownership_if_needed "$gluster_user" "$gluster_group" "$brick_path"; then
        return 1
    fi
    
    if ! change_permissions_if_needed 777 "$brick_path"; then
        return 1
    fi

    return 0
}
create_gluster_volume() {
    local volume_name="$1"
    local local_ip="$2"
    local brick_path="$3"
    local remote_ip="$4"

    if [[ -z "$volume_name" || -z "$local_ip" || -z "$brick_path" || -z "$remote_ip" ]]; then
        echo "Hata: Eksik parametreler."
        echo "Kullanım: create_gluster_volume <volume_name> <local_ip> <brick_path> <remote_ip>"
        return 1
    fi

    # Volume'un zaten mevcut olup olmadığını kontrol et
    if sudo gluster volume info "$volume_name" &>/dev/null; then
        echo "Uyarı: GlusterFS volume '$volume_name' zaten mevcut. İşlem yapılmadı."
        return 0
    fi

    echo "GlusterFS volume oluşturuluyor: $volume_name"
    sudo gluster volume create "$volume_name" replica 2 \
        "$local_ip:$brick_path" \
        "$remote_ip:$brick_path" force
    if [[ $? -ne 0 ]]; then
        echo "Hata: GlusterFS volume oluşturulamadı. Lütfen logları kontrol edin."
        return 1
    fi

    echo "GlusterFS volume başarıyla oluşturuldu: $volume_name"
    return 0
}

start_gluster_volume() {
    local volume_name="$1"

    if [[ -z "$volume_name" ]]; then
        echo "Hata: Volume adı belirtilmedi."
        return 1
    fi

    # Volume durumunu kontrol et
    local volume_status
    volume_status=$(sudo gluster volume info "$volume_name" | grep -i "Status:" | awk '{print $2}')

    if [[ "$volume_status" == "Started" ]]; then
        echo "Uyarı: GlusterFS volume '$volume_name' zaten başlatılmış. İşlem yapılmadı."
        return 0
    fi

    echo "GlusterFS volume başlatılıyor: $volume_name"
    sudo gluster volume start "$volume_name"
    if [[ $? -ne 0 ]]; then
        echo "Hata: GlusterFS volume başlatılamadı. Lütfen logları kontrol edin."
        return 1
    fi

    echo "GlusterFS volume başarıyla başlatıldı: $volume_name"
    return 0
}


mount_gluster_volume() {
    local volume_name="$1"
    local mount_point="$2"
    local ip="$3"
    local gluster_user="gluster"
    local gluster_group="gluster"

    if [[ -z "$volume_name" || -z "$mount_point" || -z "$ip" ]]; then
        echo "Hata: Eksik parametreler."
        echo "Kullanım: mount_gluster_volume <volume_name> <mount_point> <local_ip>"
        return 1
    fi

    # Mount edilmiş mi kontrol et
    if mount | grep -q "$mount_point"; then
        echo "Uyarı: $mount_point zaten mount edilmiş. Önce unmount ediliyor..."
        sudo umount "$mount_point"
        if [[ $? -ne 0 ]]; then
            echo "Uyarı: $mount_point unmount edilemiyor. Zorla unmount ediliyor..."
            sudo umount -l "$mount_point"
            if [[ $? -ne 0 ]]; then
                echo "Hata: $mount_point unmount edilemedi. Lütfen kontrol edin."
                return 1
            fi
        fi
        echo "$mount_point başarıyla unmount edildi."
    fi

    # Mount point dizinini kontrol et
    if [[ -d "$mount_point" ]]; then
        if [[ "$(ls -A "$mount_point")" ]]; then
            echo "Hata: $mount_point dizini dolu. Lütfen boş bir dizin belirtin ya da dizini temizleyin."
            return 1
        fi
    else
        echo "$mount_point dizini oluşturuluyor..."
        sudo mkdir -p "$mount_point"
    fi
    if ! change_ownership_if_needed "$gluster_user" "$gluster_group" "$mount_point"; then
        return 1
    fi
    
    if ! change_permissions_if_needed 777 "$mount_point"; then
        return 1
    fi

    echo "GlusterFS volume mount ediliyor: $volume_name -> $mount_point"
    sudo mount -t glusterfs "$ip:$volume_name" "$mount_point"
    if [[ $? -ne 0 ]]; then
        echo "Hata: GlusterFS volume mount edilemedi. Lütfen logları kontrol edin. (muhtemelen mount point dizininde eski glusterfs konfigürasyonunu tutan gizli klasörler var)"
        return 1
    fi

    echo "GlusterFS volume başarıyla mount edildi: $mount_point"
    return 0
}

configure_node_variables() {
    # Düğüm durumuna göre değişkenleri ayarla
    if [[ "$IS_NODE_1" == "true" ]]; then
        echo "Bu düğüm NODE1 olarak yapılandırılıyor..."
        local_ip="$NODE1_IP"
        remote_ip="$NODE2_IP"
    else
        echo "Bu düğüm NODE2 olarak yapılandırılıyor..."
        local_ip="$NODE2_IP"
        remote_ip="$NODE1_IP"
    fi
    # Ayarların çıktısını göster
    echo "Yerel IP: $local_ip"
    echo "Uzak IP: $remote_ip"
    return 0
}

create_redundant_folder() {
    local volume_name="$1"       # GlusterFS volume adı
    local brick_path="$2"        # Yerel sunucuda brick için kullanılacak dizin
    local mount_point="$3"       # Volume'ün mount edileceği dizin
    local remote_ip="$4"         # Uzak sunucunun IP adresi
    local local_ip="$5"          # Yerel sunucunun IP adresi

    # Gerekli kontrol
    if [[ -z "$volume_name" || -z "$brick_path" || -z "$mount_point" || -z "$remote_ip" || -z "$local_ip" ]]; then
        echo "Hata: Eksik parametreler."
        echo "Kullanım: create_redundant_folder <volume_name> <brick_path> <mount_point> <remote_ip> <local_ip>"
        return 1
    fi

    # Volume oluştur
    create_gluster_volume "$volume_name" "$local_ip" "$brick_path" "$remote_ip" || return 1

    # Volume başlat
    start_gluster_volume "$volume_name" || return 1

    # Volume mount et
    mount_gluster_volume "$volume_name" "$mount_point" "$local_ip" || return 1

    echo "GlusterFS yedekli klasör başarıyla oluşturuldu ve mount edildi."
    return 0
}