#!/bin/bash

purge_glusterfs() {
    echo "GlusterFS ve ilgili dosyalar tamamen kaldırılıyor..."

    # GlusterFS servisini kontrol et
    if systemctl is-active --quiet glusterd; then
        # GlusterFS volume'lerini durdur ve sil
        echo "GlusterFS volume'leri durduruluyor ve siliniyor..."
        sudo gluster volume list | while read volume_name; do
            if [[ -n "$volume_name" ]]; then
                echo "Volume durduruluyor: $volume_name"
                sudo gluster volume stop "$volume_name" force
                echo "Volume siliniyor: $volume_name"
                sudo gluster volume delete "$volume_name"
            fi
        done
            # GlusterFS peer'lerini kaldır
        echo "GlusterFS peer'leri kaldırılıyor..."
        sudo gluster peer status | grep 'Hostname:' | awk '{print $2}' | while read peer; do
            echo "Peer kaldırılıyor: $peer"
            sudo gluster peer detach "$peer" force
        done
    fi

    # GlusterFS brick'lerini temizle
    echo "GlusterFS brick dizinleri temizleniyor..."
    sudo rm -rf /data/glusterfs/brick1/*

    # GlusterFS paketlerini kaldır
    echo "GlusterFS paketleri kaldırılıyor..."
    sudo apt-get purge -y glusterfs-server glusterfs-client glusterfs-common
    if [[ $? -ne 0 ]]; then
        echo "Hata: GlusterFS paketleri kaldırılırken bir sorun oluştu."
        return 1
    fi

    # GlusterFS ile ilgili kalan dosyaları temizle
    echo "GlusterFS ile ilgili kalan dosyalar temizleniyor..."
    sudo rm -rf /var/lib/glusterd /etc/glusterfs /var/log/glusterfs /data/glusterfs
    if [[ $? -ne 0 ]]; then
        echo "Hata: GlusterFS dosyaları temizlenirken bir sorun oluştu."
        return 1
    fi

    # GlusterFS ile ilgili mount noktalarını kaldır
    echo "GlusterFS mount noktaları kaldırılıyor..."
    mount | grep glusterfs | awk '{print $3}' | while read mount_point; do
        sudo umount -l "$mount_point"
        if [[ $? -ne 0 ]]; then
            echo "Hata: $mount_point mount noktası kaldırılırken bir sorun oluştu."
        else
            echo "$mount_point başarıyla kaldırıldı."
        fi
    done

    # Paket listelerini temizle
    echo "Paket listeleri temizleniyor..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y

    # GlusterFS ile ilgili kernel modüllerini kaldır
    echo "GlusterFS kernel modülleri kaldırılıyor..."
    sudo modprobe -r fuse
    if [[ $? -ne 0 ]]; then
        echo "Uyarı: GlusterFS kernel modülü kaldırılırken bir sorun oluştu. Modül zaten yüklü olmayabilir."
    else
        echo "GlusterFS kernel modülü başarıyla kaldırıldı."
    fi

    echo "GlusterFS ve ilgili tüm dosyalar başarıyla kaldırıldı."
    return 0
}