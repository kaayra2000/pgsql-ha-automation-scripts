#!/bin/bash
# Script'in bulunduğu dizini alma
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/default_variables.sh"
source "$ROOT_DIR/general_functions.sh"
ARGUMENT_CFG_FILE="$ROOT_DIR/arguments.cfg"

# Argümanları tanımlayan fonksiyon
define_arguments() {
    # Argümanları bir dizide tanımla
    ARGUMENTS=(
        # Anahtar                   Komut Satırı Argümanı                Varsayılan Değer                       Yardım Açıklaması

        # HAProxy Argümanları
        "NODE1_IP"                  "--node1-ip"                         "$DEFAULT_NODE1_IP"                    "1. Düğümün IP adresi"
        "NODE2_IP"                  "--node2-ip"                         "$DEFAULT_NODE2_IP"                    "2. Düğümün IP adresi"
        "HAPROXY_BIND_PORT"         "--haproxy-bind-port"                "$DEFAULT_HAPROXY_BIND_PORT"           "HAProxy bağlantı portu"
        "PGSQL_PORT"                "--pgsql-port"                       "$DEFAULT_PGSQL_PORT"                  "PostgreSQL portu"
        "HAPROXY_PORT"              "--haproxy-port"                     "$DEFAULT_HAPROXY_PORT"                "HAProxy portu"
        "PGSQL_BIND_PORT"           "--pgsql-bind-port"                  "$DEFAULT_PGSQL_BIND_PORT"             "PostgreSQL bağlantı portu"

        # Keepalived Argümanları
        "KEEPALIVED_INTERFACE"      "--keepalived-interface"             "$DEFAULT_KEEPALIVED_INTERFACE"        "Ağ arayüzü"
        "SQL_VIRTUAL_IP"            "--sql-virtual-ip"                   "$DEFAULT_SQL_VIRTUAL_IP"              "SQL sanal IP adresi"
        "DNS_VIRTUAL_IP"            "--dns-virtual-ip"                   "$DEFAULT_DNS_VIRTUAL_IP"              "DNS sanal IP adresi"
        "KEEPALIVED_PRIORITY"       "--keepalived-priority"              "$DEFAULT_KEEPALIVED_PRIORITY"         "Keepalived önceliği"
        "KEEPALIVED_STATE"          "--keepalived-state"                 "$DEFAULT_KEEPALIVED_STATE"            "Başlangıç durumu (MASTER/BACKUP)"
        "SQL_CONTAINER_NAME"        "--sql-container-name"               "$DEFAULT_SQL_CONTAINER_NAME"          "SQL konteyner adı"
        "DNS_CONTAINER_NAME"        "--dns-container-name"               "$DEFAULT_DNS_CONTAINER_NAME"          "DNS konteyner adı"

        # DNS Argümanları
        "DNS_PORT"                  "--dns-port"                         "$DEFAULT_DNS_PORT"                    "DNS portu"
        "DNS_DOCKER_FORWARD_PORT"   "--dns-docker-forward-port"          "$DEFAULT_DNS_DOCKER_FORWARD_PORT"     "Docker'a yönlendirilecek port"

        # Patroni Argümanları
        "PATRONI_NODE_NAME"         "--patroni-node-name"                "$DEFAULT_PATRONI_NODE_NAME"           "Düğüm adı"
        "ETCD_IP"                   "--etcd-ip"                          "$DEFAULT_ETCD_IP"                     "ETCD IP adresi"
        "REPLIKATOR_KULLANICI_ADI"  "--replicator-username"              "$DEFAULT_REPLIKATOR_KULLANICI_ADI"    "Replikasyon kullanıcı adı"
        "REPLICATOR_SIFRESI"        "--replicator-password"              "$DEFAULT_REPLICATOR_SIFRESI"          "Replikasyon şifresi"
        "POSTGRES_SIFRESI"          "--postgres-password"                "$DEFAULT_POSTGRES_SIFRESI"            "Postgres şifresi"
        "IS_NODE_1"                 "--is-node1"                         "$DEFAULT_IS_NODE_1"                   "Bu düğüm 1. düğüm mü?"

        # ETCD Argümanları
        "ETCD_CLIENT_PORT"          "--etcd-client-port"                 "$DEFAULT_ETCD_CLIENT_PORT"            "ETCD istemci portu"
        "ETCD_PEER_PORT"            "--etcd-peer-port"                   "$DEFAULT_ETCD_PEER_PORT"              "ETCD eşler arası port"
        "ETCD_CLUSTER_TOKEN"        "--etcd-cluster-token"               "$DEFAULT_ETCD_CLUSTER_TOKEN"          "Küme belirteci"
        "ETCD_CLUSTER_KEEPALIVED_STATE" "--etcd-cluster-state"           "$DEFAULT_ETCD_CLUSTER_KEEPALIVED_STATE" "Küme durumu (new/existing)"
        "ETCD_NAME"                 "--etcd-name"                        "$DEFAULT_ETCD_NAME"                   "ETCD düğüm adı"
        "ETCD_ELECTION_TIMEOUT"     "--etcd-election-timeout"            "$DEFAULT_ETCD_ELECTION_TIMEOUT"       "Seçim zaman aşımı"
        "ETCD_HEARTBEAT_INTERVAL"   "--etcd-heartbeat-interval"          "$DEFAULT_ETCD_HEARTBEAT_INTERVAL"     "Nabız aralığı"
        "ETCD_DATA_DIR"             "--etcd-data-dir"                    "$DEFAULT_ETCD_DATA_DIR"               "Veri dizini"
    )
}

# Config değişkenini varsayılan değerlerle anahtar-değer çifti olarak başlatan fonksiyon
initialize_config() {
    declare -gA config
    local arg_count=${#ARGUMENTS[@]}
    for ((i=0; i<arg_count; i+=4)); do
        local key="${ARGUMENTS[i]}"
        local default_value="${ARGUMENTS[i+2]}"
        config["$key"]="$default_value"
    done
}

# Mevcut yapılandırma dosyasını okuyup config değişkenindeki varsayılan değerlerin yerine yazan fonksiyon
read_config_file() {
    if [ -f "$ARGUMENT_CFG_FILE" ]; then
        while IFS='=' read -r key value; do
            # Sadece tanımlanan anahtarları güncelle
            if [[ -n "${config["$key"]}" ]]; then
                config["$key"]="$value"
            fi
        done < "$ARGUMENT_CFG_FILE"
    fi
}


<<COMMENT
    Komut satırı argümanlarını işleyen fonksiyon (anahtar-değer çiftlerini config değişkenine atar)
    beklenen argüman formatı --argüman_adı argüman_değeri şeklindedir.
COMMENT
process_command_line_arguments() {
    local arg_count=${#ARGUMENTS[@]}
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_argument_help "$0" ARGUMENTS
                exit 0
                ;;
            *)
                local found=false
                for ((i=0; i<arg_count; i+=4)); do
                    local key="${ARGUMENTS[i]}"
                    local flag="${ARGUMENTS[i+1]}"
                    if [ "$1" == "$flag" ]; then
                        config["$key"]="$2"
                        shift 2
                        found=true
                        break
                    fi
                done
                if ! $found; then
                    echo "Uyarı: Bilinmeyen argüman '$1' atlanıyor"
                    shift 1
                fi
                ;;
        esac
    done
}

# Config değişkenini yapılandırma dosyasına yazan fonksiyon (anahtar dosyada varsa varolan değeri günceller yoksa ekler)
write_config_to_file() {
    for key in "${!config[@]}"; do
        update_config_file "$key" "$ARGUMENT_CFG_FILE" "${config[$key]}"
    done
}
# Anahtar-değer çiftinin dosyada olup olmadığını kontrol eder.
value_exists_in_file() {
    local key="$1"
    local filename="$2"
    local value="$3"
    grep -q "^$key=$value\$" "$filename"
}
# Anahtarın dosyada olup olmadığını kontrol eder.
key_exists_in_file() {
    local key="$1"
    local filename="$2"
    grep -q "^$key=" "$filename"
}

# Anahtar değeri yapılandırma dosyasına ekleyen veya güncelleyen fonksiyon
update_config_file() {
    local key="$1"
    local filename="$2"
    local value="$3"

    # Eğer dosya yoksa, oluştur
    touch "$filename"

    if key_exists_in_file "$key" "$filename"; then
        # Anahtar mevcut, değeri güncelle
        sed -i "s|^$key=.*|$key=$value|" "$filename"
    else
        # Anahtar yok, dosyanın sonuna ekle
        append_constant_to_file "$key" "$value" "$filename"
    fi
}

# Tüm işlemleri yürüten ana fonksiyon
parse_all_arguments() {
    define_arguments
    initialize_config
    read_config_file
    process_command_line_arguments "$@"
    write_config_to_file
    write_constants_to_file
}


# Sabitleri tanımlar.
define_constants() {
    constants=(
        "SQL_DOCKERFILE_NAME=docker_sql"
        "SQL_IMAGE_NAME=sql_image"
        "HAPROXY_SCRIPT_FOLDER=haproxy_scripts"
        "HAPROXY_SCRIPT_NAME=create_haproxy.sh"
        "ETCD_SCRIPT_FOLDER=etcd_scripts"
        "ETCD_SCRIPT_NAME=create_etcd.sh"
        "DOCKERFILE_PATH=../docker_files"
        "DNS_DOCKERFILE_NAME=docker_dns"
        "DNS_IMAGE_NAME=dns_image"
        "DNS_SHELL_SCRIPT_NAME=create_dns_server.sh"
        "ETCD_CONFIG_DIR=/etc/etcd"
        "ETCD_CONFIG_FILE=$ETCD_CONFIG_DIR/etcd.conf.yml"
        "ETCD_USER=etcd"
        "PATRONI_DATA_DIR=/data"
        "PATRONI_DIR=$PATRONI_DATA_DIR/patroni"
        "POSTGRES_USER=postgres"
    )
}

# Ana fonksiyon: Sabitleri dosyaya yazar.
write_constants_to_file() {
    local cfg_file="$ARGUMENT_CFG_FILE"

    define_constants

    if [ ! -f "$cfg_file" ]; then
        write_all_constants_to_file "$cfg_file"
    else
        process_existing_config_file "$cfg_file"
    fi
}

# Tüm sabitleri dosyaya yazar.
write_all_constants_to_file() {
    local cfg_file="$1"

    for const in "${constants[@]}"; do
        local key=$(extract_key "$const")
        local value=$(extract_value "$const")
        echo "$key=$value" >> "$cfg_file"
    done
    echo "Sabitler \"$cfg_file\" dosyasına yazıldı."
}

# Mevcut yapılandırma dosyasını işler.
process_existing_config_file() {
    local cfg_file="$1"
    local overwrite_all=false

    if check_existing_constants "$cfg_file"; then
        overwrite_all=$(prompt_overwrite_confirmation)
    else
        overwrite_all=true
    fi

    handle_constants "$cfg_file" "$overwrite_all"
    echo "Sabitler \"$cfg_file\" dosyasına kaydedildi."
}

# Sabitlerden anahtarı çıkarır.
extract_key() {
    local const="$1"
    echo "$const" | cut -d'=' -f1
}

# Sabitlerden değeri çıkarır.
extract_value() {
    local const="$1"
    echo "$const" | cut -d'=' -f2-
}

# Dosyada mevcut olan sabitleri kontrol eder.
check_existing_constants() {
    local cfg_file="$1"
    for const in "${constants[@]}"; do
        local key=$(extract_key "$const")
        local value=$(extract_value "$const")
        if key_exists_in_file "$key" "$cfg_file"; then
            if ! value_exists_in_file "$key" "$cfg_file" "$value"; then
                # Anahtar mevcut ve değer farklı
                return 0  # true
            fi
            # Değer aynıysa bir şey yapma, devam et
        fi
    done
    return 1  # false
}

# Kullanıcıdan üzerine yazma izni alır.
prompt_overwrite_confirmation() {
    local cevap
    read -p "Bazı sabitler zaten mevcut. Üstlerine yazılsın mı? (e/h): " cevap
    if [[ "$cevap" =~ ^[eE]$ ]]; then
        echo true
    elif [[ "$cevap" =~ ^[hH]$ ]]; then
        echo false
    else
        echo "Geçersiz giriş, varsayılan olarak 'hayır' seçildi."
        echo false
    fi
}

# Sabitleri işler ve dosyaya yazar.
handle_constants() {
    local cfg_file="$1"
    local overwrite_all="$2"

    for const in "${constants[@]}"; do
        local key=$(extract_key "$const")
        local value=$(extract_value "$const")
        if key_exists_in_file "$key" "$cfg_file"; then
            if $overwrite_all; then
                update_constant_if_needed "$key" "$value" "$cfg_file"
            fi
        else
            append_constant_to_file "$key" "$value" "$cfg_file"
        fi
    done
}

# Anahtar dosyada varsa ve değer farklıysa günceller.
update_constant_if_needed() {
    local key="$1"
    local value="$2"
    local cfg_file="$3"

    if ! value_exists_in_file "$key" "$cfg_file" "$value"; then
        local old_value=$(grep "^$key=" "$cfg_file" | cut -d'=' -f2-)
        update_config_file "$key" "$cfg_file" "$value"
        echo "Sabit '$key' güncellendi: Eski Değer='$old_value', Yeni Değer='$value'"
    fi
}

# Sabiti dosyaya ekler.
append_constant_to_file() {
    local key="$1"
    local value="$2"
    local cfg_file="$3"
    echo "$key=$value" >> "$cfg_file"
}
