#!/bin/bash

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/../argument_parser.sh # argument_parser.sh dosyasındaki fonksiyonları kullanmak için
source $SCRIPT_DIR/../general_functions.sh


#!/bin/bash

INSTALL_GLUSTERFS_PACKAGES="glusterfs-server glusterfs-client"

###############################################################################
# Yerel makinede GlusterFS kurulumunu ve ayarlarını gerçekleştiren fonksiyon
###############################################################################
install_glusterfs_local() {
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

