#!/bin/bash
# Script'in bulunduğu dizini alma
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/default_variables.sh"
ARGUMENT_CFG_FILE="$ROOT_DIR/arguments.cfg"


# Sabitleri tanımlar.
define_constants() {
    constants=(
        "SQL_DOCKERFILE_NAME=docker_sql"                                    # docker oluşturulmak için temel alınan SQL Dockerfile adı
        "SQL_IMAGE_NAME=sql_image"                                          # docker ps çıktısında gözükecek SQL Docker imajı adı
        "PATRONI_SCRIPT_FOLDER=patroni_scripts"                             # patroni scriptlerini içeren klasör adı
        "PATRONI_SCRIPT_NAME=create_patroni.sh"                             # patroni'yi ayağa kaldırmak için kullanılan script adı
        "HAPROXY_SCRIPT_FOLDER=haproxy_scripts"                             # haproxy scriptlerini içeren klasör adı
        "HAPROXY_SCRIPT_NAME=create_haproxy.sh"                             # haproxy'yi ayağa kaldırmak için kullanılan script adı
        "ETCD_SCRIPT_FOLDER=etcd_scripts"                                   # etcd scriptlerini içeren klasör adı
        "ETCD_SCRIPT_NAME=create_etcd.sh"                                   # etcd'yi ayağa kaldırmak için kullanılan script adı
        "DOCKERFILE_PATH=../docker_files"                                   # dockerfile'ların bulunduğu klasörün göreceli yolu
        "DNS_DOCKERFILE_NAME=docker_dns"                                    # docker oluşturulmak için temel alınan DNS Dockerfile adı
        "DNS_IMAGE_NAME=dns_image"                                          # docker ps çıktısında gözükecek DNS Docker imajı adı
        "DNS_SHELL_SCRIPT_NAME=create_dns_server.sh"                        # DNS sunucusunu ayağa kaldırmak için kullanılan script adı
        "ETCD_CONFIG_DIR=/etc/etcd"                                         # etcd konfigürasyon dosyasının bulunması gereken klasör
        "ETCD_CONFIG_FILE=\$ETCD_CONFIG_DIR/etcd.conf.yml"                  # etcd konfigürasyon dosyasının tam yolu
        "ETCD_USER=etcd"                                                    # işletim sisteminde bulunacak olan etcd kullanıcısının adı
        "POSTGRES_DATA_ROOT_DIR=/var/lib/postgresql"                        # postgresql verilerinin tutulacağı kök dizin
        "POSTGRES_DATA_DIR=\$POSTGRES_DATA_ROOT_DIR/16/data"                # postgresql verilerinin tutulacağı dizin
        "POSTGRES_BIN_DIR=/usr/lib/postgresql/16/bin"                       # postgresql binary dosyalarının bulunduğu dizin
        "POSTGRES_USER=postgres"                                            # işletim sisteminde bulunacak olan postgres kullanıcısının adı
        "BOOTSTRAP_SQL_FILE=/var/lib/postgresql/patroni_bootstrap.sql"      # patroni'nin ilk ayağa kalkerken oluşturacağı kullanıcıları içeren dosya yolu
        "PATRONI_YML_PATH=/etc/patroni.yml"                                 # patroni yapılandırma dosyasının yolu
        "PATRONI_BINARY_PATH=/usr/local/bin/patroni"                        # patroni binary dosyasının bulunduğu dizin
        "DOCKER_BINARY_PATH=/usr/local/bin"                                 # docker içindeki binary dosyaların yolu
    )
}

# Argümanları tanımlayan fonksiyon
define_arguments() {
    # Argümanları bir dizide tanımla
    ARGUMENTS=(
        # Anahtar                   Komut Satırı Argümanı                Varsayılan Değer                       Yardım Açıklaması

        # HAProxy Argümanları
        "NODE1_IP"                  "--node1-ip"                         "$DEFAULT_NODE1_IP"                    "HAProxy'nin yönlendireceği ilk PostgreSQL düğümünün IP adresi"
        "NODE2_IP"                  "--node2-ip"                         "$DEFAULT_NODE2_IP"                    "HAProxy'nin yönlendireceği ikinci PostgreSQL düğümünün IP adresi"
        "HAPROXY_BIND_PORT"         "--haproxy-bind-port"                "$DEFAULT_HAPROXY_BIND_PORT"           "HAProxy'nin durum ve istatistik sayfasının HTTP üzerinden erişileceği port"
        "PGSQL_PORT"                "--pgsql-port"                       "$DEFAULT_PGSQL_PORT"                  "Arka uç PostgreSQL düğümlerinin çalıştığı port"
        "HAPROXY_PORT"              "--haproxy-port"                     "$DEFAULT_HAPROXY_PORT"                "HAProxy'nin gelen PostgreSQL bağlantıları için dinlediği port"
        "PGSQL_BIND_PORT"           "--pgsql-bind-port"                  "$DEFAULT_PGSQL_BIND_PORT"             "HAProxy'nin PostgreSQL istemci bağlantıları için dinlediği port"

        # Keepalived Argümanları
        "KEEPALIVED_INTERFACE"      "--keepalived-interface"             "$DEFAULT_KEEPALIVED_INTERFACE"        "Keepalived'in VRRP iletişimi için kullanacağı ağ arayüzü (örn: eth0)"
        "SQL_VIRTUAL_IP"            "--sql-virtual-ip"                   "$DEFAULT_SQL_VIRTUAL_IP"              "Keepalived tarafından yönetilen PostgreSQL servisi için sanal IP adresi"
        "DNS_VIRTUAL_IP"            "--dns-virtual-ip"                   "$DEFAULT_DNS_VIRTUAL_IP"              "Keepalived tarafından yönetilen DNS servisi için sanal IP adresi"
        "KEEPALIVED_PRIORITY"       "--keepalived-priority"              "$DEFAULT_KEEPALIVED_PRIORITY"         "Keepalived için öncelik değeri; daha yüksek değer, master seçiminde daha yüksek öncelik anlamına gelir (tamsayı)"
        "KEEPALIVED_STATE"          "--keepalived-state"                 "$DEFAULT_KEEPALIVED_STATE"            "Düğümün Keepalived VRRP içindeki başlangıç durumu ('MASTER' veya 'BACKUP')"
        "SQL_CONTAINER_NAME"        "--sql-container-name"               "$DEFAULT_SQL_CONTAINER_NAME"          "Keepalived'in izlediği SQL (PostgreSQL) konteynerinin adı"
        "DNS_CONTAINER_NAME"        "--dns-container-name"               "$DEFAULT_DNS_CONTAINER_NAME"          "Keepalived'in izlediği DNS konteynerinin adı"

        # DNS Argümanları
        "DNS_PORT"                  "--dns-port"                         "$DEFAULT_DNS_PORT"                    "DNS servisi için dinleme portu"
        "DNS_DOCKER_FORWARD_PORT"   "--dns-docker-forward-port"          "$DEFAULT_DNS_DOCKER_FORWARD_PORT"     "DNS Docker konteynerine yönlendirilecek ana makine portu"

        # Patroni Argümanları
        "PATRONI_NODE1_NAME"        "--patroni-node1-name"               "$DEFAULT_PATRONI_NODE1_NAME"          "Patroni küme yapılandırmasındaki birinci düğümün adı (IS_NODE_1 argümanına göre değişir)"
        "PATRONI_NODE2_NAME"        "--patroni-node2-name"               "$DEFAULT_PATRONI_NODE2_NAME"          "Patroni küme yapılandırmasındaki ikinci düğümün adı (IS_NODE_1 argümanına göre değişir)"
        "ETCD_IP"                   "--etcd-ip"                          "$DEFAULT_ETCD_IP"                     "Patroni'nin koordinasyon için kullandığı ETCD kümesinin IP adresi"
        "REPLIKATOR_KULLANICI_ADI"  "--replicator-username"              "$DEFAULT_REPLIKATOR_KULLANICI_ADI"    "PostgreSQL replikasyon kullanıcısı için kullanıcı adı"
        "REPLICATOR_SIFRESI"        "--replicator-password"              "$DEFAULT_REPLICATOR_SIFRESI"          "PostgreSQL replikasyon kullanıcısı için şifre"
        "POSTGRES_SIFRESI"          "--postgres-password"                "$DEFAULT_POSTGRES_SIFRESI"            "PostgreSQL süper kullanıcı 'postgres' için şifre"
        "IS_NODE_1"                 "--is-node1"                         "$DEFAULT_IS_NODE_1"                   "Bu düğümün kümedeki ilk düğüm olup olmadığını belirten bayrak. Bu bayrağa göre patroni ip atamaları yapılıyor. (true/false)"
        "PATRONI_ADMIN_USER"        "--patroni-admin-user"               "$DEFAULT_PATRONI_ADMIN_USER"          "Patroni başlatılırken veri tabanında oluşturulacak yönetici kullanıcı adı"
        "PATRONI_ADMIN_PASSWORD"    "--patroni-admin-password"           "$DEFAULT_PATRONI_ADMIN_PASSWORD"      "Patroni başlatılırken veri tabanında oluşturulacak yönetici kullanıcı şifresi"

        # ETCD Argümanları
        "ETCD_CLIENT_PORT"          "--etcd-client-port"                 "$DEFAULT_ETCD_CLIENT_PORT"            "ETCD istemci isteklerinin hizmet verdiği port"
        "ETCD_PEER_PORT"            "--etcd-peer-port"                   "$DEFAULT_ETCD_PEER_PORT"              "ETCD küme düğümleri arasındaki eşler arası iletişim için kullanılan port"
        "ETCD_CLUSTER_TOKEN"        "--etcd-cluster-token"               "$DEFAULT_ETCD_CLUSTER_TOKEN"          "ETCD kümesini benzersiz bir şekilde tanımlayan belirteç"
        "ETCD_CLUSTER_KEEPALIVED_STATE" "--etcd-cluster-state"           "$DEFAULT_ETCD_CLUSTER_KEEPALIVED_STATE" "ETCD kümesinin başlangıç durumu ('new' için ilk kurulum veya 'existing' düğüm ekleme)"
        "ETCD_NAME"                 "--etcd-name"                        "$DEFAULT_ETCD_NAME"                   "Bu ETCD düğümünün küme içindeki adı"
        "ETCD_ELECTION_TIMEOUT"     "--etcd-election-timeout"            "$DEFAULT_ETCD_ELECTION_TIMEOUT"       "ETCD seçim zaman aşımı süresi (milisaniye cinsinden, örn: 1000)"
        "ETCD_HEARTBEAT_INTERVAL"   "--etcd-heartbeat-interval"          "$DEFAULT_ETCD_HEARTBEAT_INTERVAL"     "ETCD nabız aralığı süresi (milisaniye cinsinden, örn: 500)"
        "ETCD_DATA_DIR"             "--etcd-data-dir"                    "$DEFAULT_ETCD_DATA_DIR"               "ETCD verilerinin saklanacağı dizin"
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
