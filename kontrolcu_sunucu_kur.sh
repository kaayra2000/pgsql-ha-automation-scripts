#!/bin/bash
source fonksiyonlar.sh
source varsayilan_degiskenler.sh # varsayilan_degiskenler.sh dosyasındaki değişkenleri kullanmak için
ETCD_IP_ADRESI="${1:-$VARSAYILAN_ETCD_IP_ADRESI}"

bash ip_ayari_sifirla.sh
check_success "IP ayarları sıfırlanırken bir hata oluştu."

bash etcd_kur.sh $ETCD_IP_ADRESI
check_success "etcd kurulumu sırasında bir hata oluştu."

bash ha_proxy_kur.sh
check_success "ha_proxy kurulumu sırasında bir hata oluştu."

# bu işlem sonrasında node'ların kendi arasında haberleşebilmesini sağlamak için internet ayarlarından bridge arayüzünü seçmek lazım
statik_ip_ata $VARSAYILAN_ARAYUZ $VARSAYILAN_ETCD_IP_ADRESI $VARSAYILAN_NETMASK $VARSAYILAN_GATEWAY $VARSAYILAN_DNS
check_success "IP adresi atanırken bir hata oluştu."

hosts_dosyasina_yaz $VARSAYILAN_NODE_1_IP_ADRESI $VARSAYILAN_NODE_2_IP_ADRESI $VARSAYILAN_ETCD_IP_ADRESI $VARSAYILAN_NODE_1_HOST_ADI $VARSAYILAN_NODE_2_HOST_ADI $VARSAYILAN_ETCD_HOST_ADI
check_success "/etc/hosts dosyasına yazılırken bir hata oluştu."

ha_proxy_etkinlestir
check_success "ha_proxy etkinleştirilirken bir hata oluştu."

etcd_etkinlestir 
check_success "etcd etkinleştirilirken bir hata oluştu."