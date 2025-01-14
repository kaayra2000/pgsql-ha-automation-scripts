#!/bin/bash

purge_glusterfs() {
    echo "GlusterFS ve ilgili dosyalar tamamen kaldırılıyor..."

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

    # Brick dizinlerini temizle
    echo "Brick dizinleri temizleniyor..."
    sudo rm -rf /data/glusterfs/brick1/*
    sudo rm -rf /mnt/glusterfs/*

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

    # GlusterFS ile ilgili iptables kurallarını temizle
    echo "GlusterFS ile ilgili iptables kuralları temizleniyor..."
    sudo iptables -S | grep glusterfs | while read rule; do
        sudo iptables -D $rule
    done

    echo "GlusterFS ve ilgili tüm dosyalar başarıyla kaldırıldı."
    return 0
}