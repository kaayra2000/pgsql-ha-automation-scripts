#!/bin/bash

attach_iso_to_vm() {
    local VM_NAME="$1"
    local ISO_PATH="$2"

    # ISO dosyasını kontrol et
    if [ ! -f "$ISO_PATH" ]; then
        echo "Hata: ISO dosyası '$ISO_PATH' bulunamadı."
        exit 1
    fi

    # Storage controller'ı kontrol et ve gerekirse oluştur
    if ! VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -q "Storage Controller Name (0):"; then
        VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
    fi
    
    # ISO'yu bağla
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"
}
vm_yapilandir() {
    local VM_NAME="$1"
    local DISK_PATH="$2"
    local VM_DISK_SIZE="$3"
    local GUEST_ADDITION="$4"

    # VM yapılandırma
    VBoxManage modifyvm "$VM_NAME" --memory 4096 --vram 128 --cpus 2
    VBoxManage modifyvm "$VM_NAME" --nic1 nat
    VBoxManage modifyvm "$VM_NAME" --ostype Ubuntu_64

    # Disk ve storage controller kontrolü
    if [ ! -f "$DISK_PATH" ]; then
        if ! VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -q "SATA Controller"; then
            VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
        fi
        VBoxManage createhd --filename "$DISK_PATH" --size $VM_DISK_SIZE
        VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$DISK_PATH"
    else
        echo "Disk '$DISK_PATH' zaten var."
    fi

    # ISO dosyasını bağlama
    attach_iso_to_vm "$VM_NAME" "$ISO_PATH"
    # Guest Additions bağlama
    attach_iso_to_vm "$VM_NAME" "$GUEST_ADDITION"
}


vm_olustur(){
    local VM_NAME="$1"
    # VM oluştur
    if ! VBoxManage showvminfo "$VM_NAME" > /dev/null 2>&1; then
        VBoxManage createvm --name "$VM_NAME" --register
    else
        echo "VM '$VM_NAME' zaten var."
    fi
}

# VM ayarları
VM_NAME="${1:-master}"
ISO_PATH="${2:-ubuntu-22.04.4-desktop-amd64.iso}"
GUEST_ADDITION="${3:-VBoxGuestAdditions_7.0.14.iso}"
VM_DISK_SIZE=50000
KOK_DISK="/media/internet/5deedc4d-22d0-4061-b35d-1e54b69fa5f2"
DISK_PATH="$KOK_DISK/VirtualBox VMs/$VM_NAME/$VM_NAME.vdi"

vm_olustur "$VM_NAME"
vm_yapilandir "$VM_NAME" "$DISK_PATH" "$VM_DISK_SIZE" "$GUEST_ADDITION"

echo "VM '$VM_NAME' başarıyla oluşturuldu ve yapılandırıldı."

