#!/bin/bash

get_log_path() {
    local CONTAINER_NAME=$1
    echo "/var/log/${CONTAINER_NAME}_check.log"
}

# ilgili kontrol scriptinin log dosyasını oluştur
setup_container_log() {
    local CONTAINER_NAME=$1
    local LOG_FILE=$(get_log_path "${CONTAINER_NAME}")

    echo "Log dosyası kontrolü yapılıyor: ${LOG_FILE}"

    # Log dosyasının varlığını kontrol et
    if [ ! -f "${LOG_FILE}" ]; then
        echo "Log dosyası bulunamadı. Oluşturuluyor..."
        sudo touch "${LOG_FILE}"
        sudo chown keepalived_script:keepalived_script "${LOG_FILE}"
        sudo chmod 644 "${LOG_FILE}"
        echo "Log dosyası oluşturuldu: ${LOG_FILE}"
    else
        echo "Log dosyası mevcut. İzinler kontrol ediliyor..."

        # Dosya sahipliğini kontrol et
        OWNER=$(stat -c '%U:%G' "${LOG_FILE}")
        if [ "${OWNER}" != "keepalived_script:keepalived_script" ]; then
            echo "Dosya sahipliği düzeltiliyor..."
            sudo chown keepalived_script:keepalived_script "${LOG_FILE}"
        fi

        # Dosya izinlerini kontrol et
        PERMS=$(stat -c '%a' "${LOG_FILE}")
        if [ "${PERMS}" != "644" ]; then
            echo "Dosya izinleri düzeltiliyor..."
            sudo chmod 644 "${LOG_FILE}"
        fi
    fi
}
