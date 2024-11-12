#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/../general_functions.sh

HELP_CODE=2  # Yardım gösterildiğinde döneceğimiz kod

# Yardım mesajını gösteren fonksiyon
show_help() {
    local descriptions_name="$1"
    local -n descriptions_ref="$descriptions_name"

    echo "Docker Yapılandırma Scripti"
    echo
    echo "Kullanım: $0 [seçenekler]"
    echo
    echo "Seçenekler:"
    for arg in "${!descriptions_ref[@]}"; do
        printf "  %-25s %s\n" "$arg" "${descriptions_ref[$arg]}"
    done
    return 0
}

# Argüman işleme fonksiyonu
process_argument() {
    local arg_key="$1"
    local arg_value="$2"
    local keys_name="$3"
    local config_name="$4"
    local descriptions_name="$5"

    if [ -z "$arg_value" ] || [[ "$arg_value" == -* ]]; then
        echo "Hata: '$arg_key' için değer belirtilmedi" >&2
        show_help "$descriptions_name"
        return 1
    fi

    if ! validate_port "$arg_value"; then
        return 1
    fi

    local -n keys_ref="$keys_name"
    local -n config_ref="$config_name"

    for config_key in "${!keys_ref[@]}"; do
        if [ "${keys_ref[$config_key]}" == "$arg_key" ]; then
            config_ref[$config_key]="$arg_value"
            return 0
        fi
    done
    echo "Hata: Argüman eşleştirme bulunamadı" >&2
    return 1
}

# Genel argüman parse fonksiyonu
parse_arguments() {
    local keys_name="$1"
    local descriptions_name="$2"
    local config_name="$3"
    local unknown_arg_handling="$4"  # "skip" veya "error"
    local help_exit="$5"             # "exit" veya "continue" (artık kullanılmıyor)
    shift 5

    local -n keys_ref="$keys_name"
    local -n descriptions_ref="$descriptions_name"
    local -n config_ref="$config_name"

    local status=0

    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help "$descriptions_name"
            return $HELP_CODE
            ;;
        *)
            local found=false
            for key in "${!keys_ref[@]}"; do
                if [ "$1" == "${keys_ref[$key]}" ]; then
                    if ! process_argument "$1" "$2" "$keys_name" "$config_name" "$descriptions_name"; then
                        return 1
                    fi
                    found=true
                    shift 2
                    break
                fi
            done

            if ! $found; then
                if [ "$unknown_arg_handling" == "skip" ]; then
                    shift 1
                    continue
                else
                    echo "Hata: Bilinmeyen argüman '$1'" >&2
                    show_help "$descriptions_name"
                    return 1
                fi
            fi
            ;;
        esac
    done

    # Değişkenleri export et
    for key in "${!config_ref[@]}"; do
        export "$key"="${config_ref[$key]}"
    done

    return $status
}

# DNS parser fonksiyonu
dns_parser() {
    # Varsayılan değerleri ayarla
    declare -A config=(
        ["HOST_PORT"]="53"
        ["DNS_PORT"]="53"
    )

    # Argüman anahtarları
    declare -A ARG_KEYS=(
        ["HOST_PORT"]="--host-port"
        ["DNS_PORT"]="--dns-port"
    )

    # Argüman tanımlamaları
    declare -A ARG_DESCRIPTIONS=(
        ["${ARG_KEYS[HOST_PORT]}"]="Host üzerinde yönlendirilecek port (varsayılan: ${config[HOST_PORT]})"
        ["${ARG_KEYS[DNS_PORT]}"]="Docker DNS port numarası (varsayılan: ${config[DNS_PORT]})"
    )

    # Bilinmeyen argümanlara hata ver ve yardım mesajı gösterildikten sonra çık
    parse_arguments ARG_KEYS ARG_DESCRIPTIONS config "error" "exit" "$@"
    return $?
}

# SQL parser fonksiyonu
sql_parser() {
    # Varsayılan değerleri ayarla
    declare -A config=(
        ["HOST_PORT"]="8404"
        ["HAPROXY_PORT"]="8404"
    )

    # Argüman anahtarları
    declare -A ARG_KEYS=(
        ["HOST_PORT"]="--host-port"
        ["HAPROXY_PORT"]="--haproxy-port"
    )

    # Argüman tanımlamaları
    declare -A ARG_DESCRIPTIONS=(
        ["${ARG_KEYS[HOST_PORT]}"]="Host üzerinde yönlendirilecek port (varsayılan: ${config[HOST_PORT]})"
        ["${ARG_KEYS[HAPROXY_PORT]}"]="HAProxy port numarası (varsayılan: ${config[HAPROXY_PORT]})"
    )

    # Bilinmeyen argümanları atla ve yardım mesajı gösterildikten sonra çalışmaya devam et
    parse_arguments ARG_KEYS ARG_DESCRIPTIONS config "skip" "continue" "$@"
    return $?
}