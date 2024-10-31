#!/bin/bash
# IP adres formatını kontrol et
validate_ip() {
    local ip=$1
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ ! $ip =~ $ip_regex ]]; then
        echo "Hata: Geçersiz IP adresi formatı: $ip"
        exit 1
    fi
}

# Port numarası kontrolü
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Hata: Geçersiz port numarası: $port"
        exit 1
    fi
}
