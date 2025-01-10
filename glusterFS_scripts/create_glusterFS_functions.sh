#!/bin/bash

install_glusterfs_local_and_remote() {
    echo "Yerel sunucuda GlusterFS kurulumu başlatılıyor..."
    install_glusterfs || return 1

    echo "Uzak sunucuda GlusterFS kurulumu başlatılıyor..."
    ssh -t "$remote_user@$remote_ip" "$(declare -f install_glusterfs); install_glusterfs" || return 1
    return 0
}

# Trusted storage pool'a ekleme işlemleri
add_to_trusted_storage_pool_local_and_remote() {
    echo "Uzak sunucuda trusted storage pool'a ekleme işlemi başlatılıyor..."
    ssh -t "$remote_user@$remote_ip" "$(declare -f add_to_trusted_storage_pool); add_to_trusted_storage_pool $local_ip" || return 1

    echo "Yerel sunucuda trusted storage pool'a ekleme işlemi başlatılıyor..."
    add_to_trusted_storage_pool "$remote_ip" || return 1
    return 0
}


check_and_prepare_brick_path_local_and_remote() {
    local brick_path="$1"
    echo "Yerel sunucuda brick dosya yolu kontrol edilip oluşturuluyor..."
    check_and_prepare_brick_path "$brick_path" || return 1
    echo "Uzak sunucuda brick dosya yolu kontrol edilip oluşturuluyor..."
    ssh -t "$remote_user@$remote_ip" "$(declare -f check_and_prepare_brick_path); check_and_prepare_brick_path $brick_path" || return 1
    return 0
}

# Yedekli GlusterFS volume oluşturma işlemleri
create_redundant_folder_local_and_remote() {
    local volume_name="$1"
    local brick_path="$2"
    local mount_point="$3"
    local local_ip="$4"
    local remote_ip="$5"

    echo "Yerel sunucuda yedekli GlusterFS volume oluşturuluyor..."
    create_redundant_folder "$volume_name" "$brick_path" "$mount_point" "$remote_ip" "$local_ip" || return 1

    echo "Uzak sunucuda yedekli GlusterFS volume oluşturuluyor..."
    ssh -t "$remote_user@$remote_ip" "$(declare -f create_redundant_folder create_gluster_volume start_gluster_volume mount_gluster_volume); create_redundant_folder $volume_name $brick_path $mount_point $local_ip $remote_ip" || return 1
    return 0
}
