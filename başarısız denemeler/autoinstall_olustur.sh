#!/bin/bash

# ISO dosyasını argüman olarak al veya varsayılan değeri kullan
ISO_DOSYASI="${1:-ubuntu-22.04.4-desktop-amd64.iso}"
CUSTOM_ISO="custom-iso"
GRUB_PATH="$CUSTOM_ISO/boot/grub"
AUTOINSTALL_FOLDER="$GRUB_PATH/autoinstall"
USER_DATA="$AUTOINSTALL_FOLDER/user-data"
CUSTOM_ISO_DOSYASI="custom-$ISO_DOSYASI"
GRUB_CFG_PATH="$GRUB_PATH/grub.cfg"
# Varsayılan içerik
DEFAULT_CONTENT=$(cat <<EOF
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: ahmet-vm
    username: ahmet
    password: 123
  storage:
    layout:
      name: lvm
  locale: tr_TR.UTF-8
  keyboard:
    layout: tr
EOF
)

# Gerekli komutların yüklü olup olmadığını kontrol et
for komut in bsdtar xorriso mkisofs; do
    if ! command -v "$komut" &> /dev/null; then
        echo "Hata: '$komut' komutu yüklü değil."
        exit 1
    fi
done

if [ -n "$2" ]; then
    if [ -f "$2" ]; then
        DEFAULT_CONTENT=$(cat "$2")
    else
        echo "Hata: '$2' bir dosya değil veya mevcut değil."
        exit 1
    fi
fi


# ISO dosyasının varlığını kontrol et
if [ ! -f "$ISO_DOSYASI" ]; then
    echo "$ISO_DOSYASI dosyası bulunamadı."
    exit 1
fi

# Çalışma dizininin varlığını kontrol et
if [ -d "$CUSTOM_ISO" ]; then
    echo "$CUSTOM_ISO dizini zaten var. Temizlensin mi? (e/h):"
    read -r CEVAP
    if [ "$CEVAP" = "e" ]; then
        sudo rm -rf "$CUSTOM_ISO"
        echo "$CUSTOM_ISO dizini temizlendi."
    else
        echo "İşlem iptal edildi."
        exit 1
    fi
fi


# Çalışma dizini oluştur ve ISO'yu ayıkla
mkdir $CUSTOM_ISO


echo "$ISO_DOSYASI dosyası $CUSTOM_ISO klasörüne ayıklanıyor"
# ISO'yu ayıkla ve başarısızlık durumunda hata mesajı yazdır
if ! bsdtar -C $CUSTOM_ISO -xf "$ISO_DOSYASI"; then
    echo "$ISO_DOSYASI dosyası ayıklanırken bir hata oluştu."
    exit 1
fi



# grub.cfg dosyasını düzenle
if [ -f "$GRUB_CFG_PATH" ]; then
    # Autoinstall seçeneğini ekle
    chmod 777 -R "$GRUB_PATH"
    mkdir -p $AUTOINSTALL_FOLDER
    echo "menuentry 'Install Ubuntu (Autoinstall)' {" >> "$GRUB_CFG_PATH"
    echo "    set gfxpayload=keep" >> "$GRUB_CFG_PATH"
    echo "    linux /casper/vmlinuz autoinstall ds=nocloud-net;s=/cdrom/$USER_DATA ---" >> "$GRUB_CFG_PATH"
    echo "    initrd /casper/initrd" >> "$GRUB_CFG_PATH"
    echo "}" >> "$GRUB_CFG_PATH"
else
    echo "Hata: '$GRUB_CFG_PATH' dosyası bulunamadı."
    exit 1
fi
# İçeriği $CUSTOM_ISO klasörünün altına user-data adıyla yaz
echo "$DEFAULT_CONTENT" > "$USER_DATA"

echo "$CUSTOM_ISO_DOSYASI oluşturulmaya başlandı"
# Özelleştirilmiş ISO'yu oluştur
xorriso -as mkisofs -r \
  -V "CUSTOM_UBUNTU" \
  -o "$CUSTOM_ISO_DOSYASI" \
  -J -l \
  -b boot/grub/i386-pc/eltorito.img \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  $CUSTOM_ISO

