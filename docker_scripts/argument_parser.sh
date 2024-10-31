#!/bin/bash

# Varsayılan değerleri ayarla
declare -A config=(
    ["DNS_PORT"]="53"
    ["HOST_PORT"]="53"
    ["HAPROXY_PORT"]="5432"
)

# Argüman anahtarları
declare -A ARG_KEYS=(
    ["DNS_PORT"]="--dns-port"
    ["HOST_PORT"]="--host-port"
    ["HAPROXY_PORT"]="--haproxy-port"
)

# Argüman tanımlamaları
declare -A ARG_DESCRIPTIONS=(
    ["${ARG_KEYS[DNS_PORT]}"]="Docker port numarası (varsayılan: ${config[DNS_PORT]})"
    ["${ARG_KEYS[HOST_PORT]}"]="Host üzerinde yönlendirilecek port (varsayılan: ${config[HOST_PORT]})"
    ["${ARG_KEYS[HAPROXY_PORT]}"]="HAProxy port numarası (varsayılan: ${config[HAPROXY_PORT]})"
)

# Yardım mesajını göster
show_help() {
    echo "Docker Yapılandırma Scripti"
    echo
    echo "Kullanım: $0 [seçenekler]"
    echo
    echo "Seçenekler:"
    for arg in "${!ARG_DESCRIPTIONS[@]}"; do
        printf "  %-25s %s\n" "$arg" "${ARG_DESCRIPTIONS[$arg]}"
    done
}

# Port numarası doğrulama
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Hata: Geçersiz port numarası '$port'. Port 1-65535 arasında olmalıdır." >&2
        return 1
    fi
    return 0
}

# Argüman işleme fonksiyonu
process_argument() {
    local arg_key=$1
    local arg_value=$2

    if [ -z "$arg_value" ] || [[ "$arg_value" == -* ]]; then
        echo "Hata: '$arg_key' için değer belirtilmedi" >&2
        show_help
        exit 1
    fi

    if ! validate_port "$arg_value"; then
        exit 1
    fi

    # ARG_KEYS dizisini tersine çevirerek config key'ini bul
    for config_key in "${!ARG_KEYS[@]}"; do
        if [ "${ARG_KEYS[$config_key]}" == "$arg_key" ]; then
            config[$config_key]="$arg_value"
            return
        fi
    done
}

# Argümanları parse et
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help
            exit 0
            ;;
        *)
            local found=false
            # ARG_KEYS dizisini dolaş
            for key in "${!ARG_KEYS[@]}"; do
                if [ "$1" == "${ARG_KEYS[$key]}" ]; then
                    process_argument "$1" "$2"
                    found=true
                    shift 2
                    break
                fi
            done

            if ! $found; then
                echo "Hata: Bilinmeyen argüman '$1'" >&2
                show_help
                exit 1
            fi
            ;;
        esac
    done

    # Değişkenleri export et
    for key in "${!config[@]}"; do
        export "$key"="${config[$key]}"
    done
}
