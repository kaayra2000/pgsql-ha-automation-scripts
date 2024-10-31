#!/bin/bash

create_image() {
    # Gerekli argüman sayısını kontrol et
    if [ "$#" -lt 3 ]; then
        echo "Hata: Eksik argümanlar!" >&2
        echo "Kullanım: create_image <image_name> <dockerfile_path> <dockerfile_name> [context_path]" >&2
        return 1
    fi

    local image_name="$1"
    local dockerfile_path="$2"
    local dockerfile_name="$3"
    local context_path="${4:-.}"
    local status=0 # Fonksiyonun çıkış durumunu sakla

    # Dockerfile'ın varlığını kontrol et
    if [ ! -f "$dockerfile_path/$dockerfile_name" ]; then
        echo "Hata: Dockerfile bulunamadı: $dockerfile_path/$dockerfile_name" >&2
        return 1
    fi

    # Context path'in varlığını kontrol et
    if [ ! -d "$context_path" ]; then
        echo "Hata: Context path bulunamadı: $context_path" >&2
        return 1
    fi

    if docker image inspect "$image_name" >/dev/null 2>&1; then
        read -p "Image '$image_name' already exists. Do you want to rebuild it? (y/n): " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if docker build -t "$image_name" -f "$dockerfile_path/$dockerfile_name" "$context_path"; then
                echo "Image rebuilt successfully."
                status=0
            else
                echo "Error: Image build failed." >&2
                status=1
            fi
        else
            echo "Using existing image."
            status=0
        fi
    else
        if docker build -t "$image_name" -f "$dockerfile_path/$dockerfile_name" "$context_path"; then
            echo "New image created successfully."
            status=0
        else
            echo "Error: Image build failed." >&2
            status=1
        fi
    fi

    return $status
}
