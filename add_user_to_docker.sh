#!/bin/bash

# Docker grubunun mevcut olup olmadığını kontrol et
if getent group docker > /dev/null 2>&1; then
    echo "Docker grubu zaten mevcut."
else
    echo "Docker grubu oluşturuluyor..."
    sudo groupadd docker
fi

# Kullanıcıyı Docker grubuna ekle
echo "Kullanıcı Docker grubuna ekleniyor..."
sudo usermod -aG docker $USER

echo "Değişiklikler uygulanıyor..."

# Yeni grup üyeliğini mevcut oturuma uygula
newgrp docker << EOF

# Docker daemon'ın çalıştığından emin ol
if ! systemctl is-active --quiet docker; then
    echo "Docker daemon başlatılıyor..."
    sudo systemctl start docker
fi

echo "Docker grubu üyeliği başarıyla uygulandı ve Docker daemon çalışıyor."
echo "Artık Docker komutlarını sudo olmadan kullanabilirsiniz."

# Test amaçlı bir Docker komutu çalıştır
docker --version

EOF
