#!/bin/bash

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/glusterFS_setup.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh
source $SCRIPT_DIR/create_glusterFS_functions.sh
source $SCRIPT_DIR/set_node_variables.sh


parse_and_read_arguments "$@"

set_node_variables

# GlusterFS kurulumlarını yap
if ! install_glusterfs_local_and_remote; then
    echo "Hata: GlusterFS kurulumu başarısız oldu."
    exit 1
fi

# Trusted storage pool'a ekleme işlemlerini yap
if ! add_to_trusted_storage_pool_local_and_remote; then
    echo "Hata: Trusted storage pool'a ekleme işlemi başarısız oldu."
    exit 1
fi

if ! check_and_prepare_brick_path_local_and_remote "/data/glusterfs/brick1"; then
    echo "Hata: Brick dosya yolu kontrolü ve oluşturma işlemi başarısız oldu."
    exit 1
fi

if create_redundant_folder_local_and_remote "my_volume" "/data/glusterfs/brick1" "/mnt/glusterfs" "$local_ip" "$remote_ip"; then
    echo "Hata: Yedekli GlusterFS volume oluşturma işlemi başarısız oldu."
    exit 1
fi

echo "GlusterFS kurulumu ve yapılandırması başarıyla tamamlandı."