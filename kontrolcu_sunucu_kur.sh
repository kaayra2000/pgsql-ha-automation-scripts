#!/bin/bash
source fonksiyonlar.sh
source varsayilan_degiskenler.sh # varsayilan_degiskenler.sh dosyasındaki değişkenleri kullanmak için
ETCD_IP_ADRESI="${1:-$VARSAYILAN_ETCD_IP_ADRESI}"

bash ip_ayari_sifirla.sh
hata_kontrol "IP ayarları sıfırlanırken bir hata oluştu."

bash etcd_kur.sh $ETCD_IP_ADRESI
hata_kontrol "etcd kurulumu sırasında bir hata oluştu."

bash ha_proxy_kur.sh
hata_kontrol "ha_proxy kurulumu sırasında bir hata oluştu."

# bu işlem sonrasında node'ların kendi arasında haberleşebilmesini sağlamak için internet ayarlarından bridge arayüzünü seçmek lazım
statik_ip_ata $VARSAYILAN_ARAYUZ $VARSAYILAN_ETCD_IP_ADRESI $VARSAYILAN_NETMASK $VARSAYILAN_GATEWAY $VARSAYILAN_DNS
hata_kontrol "IP adresi atanırken bir hata oluştu."

hosts_dosyasina_yaz $VARSAYILAN_NODE_1_IP_ADRESI $VARSAYILAN_NODE_2_IP_ADRESI $VARSAYILAN_ETCD_IP_ADRESI $VARSAYILAN_NODE_1_HOST_ADI $VARSAYILAN_NODE_2_HOST_ADI $VARSAYILAN_ETCD_HOST_ADI
hata_kontrol "/etc/hosts dosyasına yazılırken bir hata oluştu."

ha_proxy_etkinlestir
hata_kontrol "ha_proxy etkinleştirilirken bir hata oluştu."

etcd_etkinlestir 
hata_kontrol "etcd etkinleştirilirken bir hata oluştu."