#!/bin/bash

# Argüman dosyasının varlığını kontrol edip gerekli fonksiyonları çağıran fonksiyon
parse_and_read_arguments() {
    parse_all_arguments "$@"
    read_arguments "$ARGUMENT_CFG_FILE" # ARGUMENT_CFG_FILE değişkeni argument_parser.sh dosyasında tanımlı
}

# Argümanları dosyadan oku ve export et
read_arguments() {
    local input_file="$1"
    if [ ! -f "$input_file" ]; then
        echo "Hata: Argüman dosyası bulunamadı: $input_file"
        exit 1
    fi
    while IFS='=' read -r key value; do
        export "$key"="$value"
    done < "$input_file"
}

check_success() {
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        local HATA_ADI="${1:-"Bir hata oluştu. Program sonlandırılıyor."}"
        echo "$HATA_ADI"
        exit 1
    fi
    return $EXIT_CODE
}

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

# Sayısal değer kontrolü için fonksiyon
validate_number() {
    local value="$1"
    local param_name="$2"
    local min_value="${3:-0}"  # Opsiyonel minimum değer, varsayılan 0
    
    if [[ ! $value =~ ^[0-9]+$ ]]; then
        echo "Hata: $param_name sayısal bir değer olmalıdır"
        return 1
    fi
    
    if (( value < min_value )); then
        echo "Hata: $param_name değeri $min_value'dan büyük olmalıdır"
        return 1
    fi
    
    return 0
}

# Dizin kontrolü ve oluşturma fonksiyonu
check_directory() {
    local dir_path="$1"
    local create_if_missing="${2:-true}"  # Opsiyonel parametre, varsayılan true
    
    if [[ ! -d "$dir_path" ]]; then
        if [[ "$create_if_missing" == "true" ]]; then
            echo "Uyarı: $dir_path dizini mevcut değil, oluşturuluyor..."
            sudo mkdir -p "$dir_path"
            if [[ $? -ne 0 ]]; then
                echo "Hata: $dir_path dizini oluşturulamadı"
                return 1
            fi
            echo "$dir_path dizini başarıyla oluşturuldu"
        else
            echo "Hata: $dir_path dizini mevcut değil"
            return 1
        fi
    fi
    
    # Dizine yazma izni kontrolü
    if [[ ! -w "$dir_path" ]]; then
        echo "Hata: $dir_path dizinine yazma izni yok"
        return 1
    fi
    
    return 0
}

set_permissions() {
    # Argüman sayısını kontrol et
    if [ "$#" -lt 3 ]; then
        echo "Hata: Eksik parametre"
        echo "Kullanım: izin_ver <kullanıcı> <dosya_veya_dizin> <izin_numarası>"
        return 1
    fi

    local kullanici="$1"
    local hedef="$2"
    local izin="$3"

    # Kullanıcının varlığını kontrol et
    if ! id "$kullanici" >/dev/null 2>&1; then
        echo "Hata: $kullanici kullanıcısı mevcut değil"
        return 1
    fi

    # Dosya veya dizinin varlığını kontrol et
    if [ ! -e "$hedef" ]; then
        echo "Hata: $hedef bulunamadı"
        return 1
    fi

    # İzinleri değiştir
    if ! chmod "$izin" "$hedef"; then
        echo "Hata: İzinler değiştirilemedi"
        return 1
    fi

    # Sahipliği değiştir
    if ! chown "$kullanici:$kullanici" "$hedef"; then
        echo "Hata: Sahiplik değiştirilemedi"
        return 1
    fi

    echo "Başarılı: $hedef için izinler ve sahiplik güncellendi"
    echo "Yeni sahip: $kullanici"
    echo "Yeni izinler: $izin"
    ls -l "$hedef"
    return 0
}


check_user_exists() {
    # Argüman sayısını kontrol et
    if [ "$#" -ne 1 ]; then
        echo "Error: Missing username parameter"
        echo "Usage: check_user_exists <username>"
        return 1
    fi

    local username="$1"

    # Kullanıcı varlığını kontrol et
    if id "$username" >/dev/null 2>&1; then
        echo "Success: User '$username' exists"
        echo "User details:"
        id "$username"
        return 0
    else
        echo "Error: User '$username' does not exist"
        return 1
    fi
}

show_argument_help() {
    local script_name="$1"
    local -n arg_array="$2"

    echo "${script_name} Kurulum ve Yapılandırma Scripti"
    echo
    echo "Kullanım: $script_name [seçenekler]"
    echo
    echo "Seçenekler:"

    declare -A options

    local arg_count=${#arg_array[@]}
    for ((i=0; i<$arg_count; i+=4)); do
        local flag="${arg_array[i+1]}"
        local description="${arg_array[i+3]}"
        options["$flag"]="$description"
    done

    # Seçenekleri bayraklara göre alfabetik olarak sıralama
    IFS=$'\n' sorted_flags=($(sort <<<"${!options[*]}"))
    unset IFS

    for flag in "${sorted_flags[@]}"; do
        printf "  %-25s %s\n" "$flag" "${options[$flag]}"
    done
}