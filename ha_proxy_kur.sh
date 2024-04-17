#!/bin/bash
source fonksiyonlar.sh
source varsayilan_degiskenler.sh # varsayilan_degiskenler.sh dosyasındaki değişkenleri kullanmak için


NODE_1_IP_ADRESI="${1:-$VARSAYILAN_NODE_1_IP_ADRESI}"
NODE_2_IP_ADRESI="${2:-$VARSAYILAN_NODE_2_IP_ADRESI}"

ha_proxy_kur
ha_proxy_konfigure_et $NODE_1_IP_ADRESI $NODE_2_IP_ADRESI