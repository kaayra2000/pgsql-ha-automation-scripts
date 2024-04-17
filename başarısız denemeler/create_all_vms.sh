#!/bin/bash

# VM isimlerini bir diziye ata
vms=("master" "replica1" "replica2")
ISO_PATH="${1:-ubuntu-22.04.4-desktop-amd64.iso}"
# Her bir VM için işlemleri gerçekleştir
for vm in "${vms[@]}"; do
    # VM'in varlığını kontrol et
    if VBoxManage showvminfo "$vm" --machinereadable &> /dev/null; then
        # VM açıksa, önce kapat
        state=$(VBoxManage showvminfo "$vm" --machinereadable | grep "VMState=" | cut -d '"' -f2)
        if [ "$state" = "running" ]; then
            echo "VM '$vm' çalışıyor, kapatılıyor..."
            VBoxManage controlvm "$vm" poweroff
            # VM'nin tamamen kapanmasını bekle
            while true; do
                state=$(VBoxManage showvminfo "$vm" --machinereadable | grep "VMState=" | cut -d '"' -f2)
                if [ "$state" = "poweroff" ] || [ "$state" = "aborted" ]; then
                    echo "VM '$vm' başarıyla kapatıldı."
                    break
                else
                    sleep 1
                fi
            done
        fi

        # Kullanıcıya VM'i silmek isteyip istemediğini sor
        echo "VM '$vm' mevcut. Silmek ister misiniz? (e/h):"
        read -r CEVAP
        if [ "$CEVAP" = "e" ]; then
            # VM'i kayıtdan sil ve dosyaları sil
            echo "VM '$vm' kayıtdan siliniyor ve dosyaları siliniyor..."
            if ! VBoxManage unregistervm "$vm" --delete; then
                echo "Hata: VM '$vm' silinirken bir sorun oluştu."
                exit 1
            fi
        else
            echo "VM '$vm' silinmedi."
            continue
        fi
    fi

    # VM'i oluştur
    echo "VM '$vm' oluşturuluyor..."
    if ! ./create_vm.sh "$vm" "$ISO_PATH"; then
        echo "Hata: VM '$vm' oluşturulurken bir sorun oluştu."
        exit 1
    fi
done

echo "Tüm işlemler başarıyla tamamlandı."
