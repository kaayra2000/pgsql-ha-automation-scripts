#!/bin/bash

source fonksiyonlar.sh
source varsayilan_degiskenler.sh

ETCD_IP_ADRESI="${1:-$VARSAYILAN_ETCD_IP_ADRESI}"

etcd_kur

etcd_konfigure_et $ETCD_IP_ADRESI $ETCD_PORT_0 $ETCD_PORT_1