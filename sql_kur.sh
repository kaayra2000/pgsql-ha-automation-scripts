#!/bin/bash
source fonksiyonlar.sh # fonksiyonlar.sh dosyasındaki fonksiyonları kullanmak için
source varsayilan_degiskenler.sh # varsayilan_degiskenler.sh dosyasındaki değişkenleri kullanmak için

bash ip_ayari_sifirla.sh
check_success "IP ayarları sıfırlanırken bir hata oluştu."

echo "PostgreSQL kurulumuna başlanıyor..."
sql_kur

echo "Patroni kurulumuna başlanıyor..."
patroni_kur

echo "PostgreSQL konfigürasyonu yapılıyor..."
sql_kullanici_olustur

echo "Patroni konfigürasyonu yapılıyor..."

# CIHAZ_TIPI, NODE_1_IP_ADRESI ve NODE_2_IP_ADRESI fonksiyonlar.sh ile alınıyor


CIHAZ_TIPI="${1:-$NODE_1}"
NODE_1_IP_ADRESI="${2:-$VARSAYILAN_NODE_1_IP_ADRESI}"
NODE_2_IP_ADRESI="${3:-$VARSAYILAN_NODE_2_IP_ADRESI}"

if [ "$CIHAZ_TIPI" = "$NODE_1" ]; then
    echo "$NODE_1 seçildi."
    patroni_konfigure_et $NODE_1_IP_ADRESI $NODE_2_IP_ADRESI $NODE_1 $VARSAYILAN_ETCD_IP_ADRESI
    STATIK_IP_ADRESI=$NODE_1_IP_ADRESI
else
    echo "$SLAVE seçildi."
    patroni_konfigure_et $NODE_2_IP_ADRESI $NODE_1_IP_ADRESI $NODE_2 $VARSAYILAN_ETCD_IP_ADRESI
    STATIK_IP_ADRESI=$NODE_2_IP_ADRESI
fi
postgres_patroniye_devret
# bu işlem sonrasında node'ların kendi arasında haberleşebilmesini sağlamak için internet ayarlarından bridge arayüzünü seçmek lazım
statik_ip_ata $VARSAYILAN_ARAYUZ $STATIK_IP_ADRESI $VARSAYILAN_NETMASK $VARSAYILAN_GATEWAY $VARSAYILAN_DNS
check_success "IP adresi atanırken bir hata oluştu."

hosts_dosyasina_yaz $NODE_1_IP_ADRESI $NODE_2_IP_ADRESI $VARSAYILAN_ETCD_IP_ADRESI $VARSAYILAN_NODE_1_HOST_ADI $VARSAYILAN_NODE_2_HOST_ADI $VARSAYILAN_ETCD_HOST_ADI
check_success "/etc/hosts dosyasına yazılırken bir hata oluştu."

echo "Tüm işlemler başarıyla tamamlandı."

