#!/bin/bash

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/glusterFS_setup.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh
source $SCRIPT_DIR/create_glusterFS_functions.sh
source $SCRIPT_DIR/set_node_variables.sh

VOLUME_NAME="varsayilan_volume"
BRICK_PATH="/data/glusterfs/brick1"
MOUNT_POINT="/mnt/glusterfs"

parse_and_read_arguments "$@"

set_node_variables
###
### Eğer bir defa volume oluşturulduysa ve farklı volumle'lar oluşturulmak isteniyorsa kurulumla ilgili bu kısımların çalıştırılmasına gerek yok.
###
# GlusterFS kurulumlarını yap
if ! install_glusterfs_local_and_remote $remote_ip $remote_user; then
    echo "Hata: GlusterFS kurulumu başarısız oldu."
    exit 1
fi

# Trusted storage pool'a ekleme işlemlerini yap
if ! add_to_trusted_storage_pool_local_and_remote "$local_ip" "$remote_ip" "$remote_user"; then
    echo "Hata: Trusted storage pool'a ekleme işlemi başarısız oldu."
    exit 1
fi
###
### Eğer bir defa volume oluşturulduysa ve farklı volumle'lar oluşturulmak isteniyorsa kurulumla ilgili bu kısımların çalıştırılmasına gerek yok.
###

if ! check_and_prepare_brick_path_local_and_remote $BRICK_PATH "$remote_ip" "$remote_user"; then
    echo "Hata: Brick dosya yolu kontrolü ve oluşturma işlemi başarısız oldu."
    exit 1
fi

# local_ip ve remote_ip değişkenleri set_node_variables fonksiyonunda tanımlanmıştır
if ! create_redundant_folder_local_and_remote $VOLUME_NAME $BRICK_PATH $MOUNT_POINT "$local_ip" "$remote_ip" "$remote_user"; then
    echo "Hata: Yedekli GlusterFS volume oluşturma işlemi başarısız oldu."
    exit 1
fi

echo "GlusterFS kurulumu ve yapılandırması başarıyla tamamlandı."