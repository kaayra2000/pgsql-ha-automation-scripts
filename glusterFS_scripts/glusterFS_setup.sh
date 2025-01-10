#!/bin/bash

INSTALL_GLUSTERFS_PACKAGES="glusterfs-server glusterfs-client"

install_glusterfs() {
    echo "Yerel makinede GlusterFS kurulumu kontrol ediliyor..."
    
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
        echo "Hata: Uzak cihaz trusted storage pool'a eklenemedi. Lütfen logları kontrol edin."
        return 1
    fi

    # Trusted storage pool'u listele
    echo "Trusted storage pool durumu:"
    sudo gluster pool list

    echo "Uzak cihaz başarıyla trusted storage pool'a eklendi."
    return 0
}


create_redundant_folder() {
    local volume_name="$1"       # GlusterFS volume adı
    local brick_path="$2"        # Yerel sunucuda brick için kullanılacak dizin
    local mount_point="$3"       # Volume'ün mount edileceği dizin
    local remote_ip="$4"         # Uzak node'un IP adresi

    # Yerel IP adresini al
    local local_ip
    local_ip=$(hostname -I | awk '{print $1}') # İlk IP adresini alır

    # Gerekli kontrol
    if [[ -z "$volume_name" || -z "$brick_path" || -z "$mount_point" || -z "$remote_ip" ]]; then
        echo "Hata: Eksik parametreler."
        echo "Kullanım: create_redundant_folder <volume_name> <brick_path> <mount_point> <remote_ip>"
        return 1
    fi

    # Yerel brick dizinini oluştur
    echo "Yerel brick dizini oluşturuluyor: $brick_path"
    sudo mkdir -p "$brick_path"
    sudo chmod 755 "$brick_path"

    # GlusterFS volume oluştur
    echo "GlusterFS volume oluşturuluyor: $volume_name"
    sudo gluster volume create "$volume_name" replica 2 \
        "$local_ip:$brick_path" \
        "$remote_ip:$brick_path" force
    if [[ $? -ne 0 ]]; then
        echo "Hata: GlusterFS volume oluşturulamadı. Lütfen logları kontrol edin."
        return 1
    fi

    # Volume'ü başlat
    echo "GlusterFS volume başlatılıyor: $volume_name"
    sudo gluster volume start "$volume_name"
    if [[ $? -ne 0 ]]; then
        echo "Hata: GlusterFS volume başlatılamadı. Lütfen logları kontrol edin."
        return 1
    fi

    # Yerel sunucuda volume'ü mount et
    echo "Yerel sunucuda volume mount ediliyor: $mount_point"
    sudo mkdir -p "$mount_point"
    sudo mount -t glusterfs "$local_ip:$volume_name" "$mount_point"
    if [[ $? -ne 0 ]]; then
        echo "Hata: GlusterFS volume mount edilemedi. Lütfen logları kontrol edin."
        return 1
    fi

    echo "GlusterFS yedekli klasör başarıyla oluşturuldu ve mount edildi."
    return 0
}