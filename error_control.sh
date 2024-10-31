#!/bin/bash

hata_kontrol() {
    local HATA_ADI="${1:-"Bir hata oluştu. Program sonlandırılıyor."}"
    if [ $? -ne 0 ]; then
        echo "$HATA_ADI"
        exit 1
    fi
}
