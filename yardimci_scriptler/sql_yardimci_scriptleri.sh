#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../arguments.cfg
source $SCRIPT_DIR/../general_functions.sh

parse_and_read_arguments "$@"

# Patroni loglarını bulunduğunuz klasöre kopyalama
patroni_log_get() {
    docker exec sql_container /bin/bash -c "cat /var/log/patroni/patroni.log" > patroni.log
    echo "Patroni logları bulunduğunuz klasöre 'patroni.log' olarak kaydedildi."
}


# Docker konteynırında çalışan Patroni servisinin loglarını ekrana yazdırma
patroni_log_print() {
    docker exec sql_container /bin/bash -c "cat /var/log/patroni/patroni.log"
}

# SQL server'a bağlanabilmek için
sql_connect_server() {
    local SQL_IP=${1:-"10.207.80.20"}
    psql -U $POSTGRES_USER -h $SQL_IP
}

# Bu fonksiyon, belirtilen IP adresindeki PostgreSQL sunucusuna bağlanır ve sabit iki sütunlu bir tablo oluşturur.
sql_create_table() {
    local TABLE_NAME=${1:-"default_table"}  # Varsayılan tablo adı
    local PASSWORD=${2:-"$POSTGRES_SIFRESI"}  # Varsayılan şifre
    local SQL_IP=${3:-"10.207.80.20"}  # Varsayılan IP adresi

    # PostgreSQL komutunu çalıştır
    PGPASSWORD="$PASSWORD" psql -U $POSTGRES_USER -h "$SQL_IP" -d $POSTGRES_USER -c "
    CREATE TABLE IF NOT EXISTS $TABLE_NAME (
        id SERIAL PRIMARY KEY,
        data TEXT NOT NULL
    );
    " && echo "Tablo '$TABLE_NAME' başarıyla oluşturuldu." || echo "Tablo oluşturulurken bir hata oluştu."
}

# Bu fonksiyon, belirtilen tabloya belirli sayıda rastgele veri ekler.
sql_insert_data() {
    local ELEMENT_COUNT=${1:-5}  # Varsayılan eleman sayısı
    local TABLE_NAME=${2:-"default_table"}  # Varsayılan tablo adı
    local PASSWORD=${3:-"$POSTGRES_SIFRESI"}  # Varsayılan şifre
    local SQL_IP=${4:-"10.207.80.20"}  # Varsayılan IP adresi

    # PostgreSQL komutunu çalıştır
    for ((i=1; i<=ELEMENT_COUNT; i++)); do
        local RANDOM_DATA="RandomData_$RANDOM"
        PGPASSWORD="$PASSWORD" psql -U $POSTGRES_USER -h "$SQL_IP" -d $POSTGRES_USER -c "
        INSERT INTO $TABLE_NAME (data) VALUES ('$RANDOM_DATA');
        " && echo "Veri eklendi: $RANDOM_DATA" || echo "Veri eklenirken bir hata oluştu."
    done
}

# PostgreSQL loglarını bulunduğunuz klasöre kopyalama
sql_log_get() {
    docker exec sql_container /bin/bash -c "ls -tr /var/lib/postgresql/16/data/log | while read file; do cat /var/lib/postgresql/16/data/log/\$file; done" > sql_logs.log
    echo "PostgreSQL logları bulunduğunuz klasöre 'sql_logs.log' olarak kaydedildi."
}

# Docker konteynırında çalışan PostgreSQL loglarını ekrana yazdırma
sql_log_print() {
    docker exec sql_container /bin/bash -c "ls -tr /var/lib/postgresql/16/data/log | while read file; do cat /var/lib/postgresql/16/data/log/\$file; done"
}

# Bu fonksiyon, belirtilen IP adresindeki PostgreSQL sunucusunda verilen SQL komutunu çalıştırır.
sql_run_command() {
    local SQL_COMMAND=${1:-""}  # Çalıştırılacak SQL komutu
    local PASSWORD=${2:-"$POSTGRES_SIFRESI"}  # Varsayılan şifre
    local SQL_IP=${3:-"10.207.80.20"}  # Varsayılan IP adresi

    if [[ -z "$SQL_COMMAND" ]]; then
        echo "SQL komutu belirtilmedi. Lütfen bir SQL komutu girin."
        return 1
    fi

    # PostgreSQL komutunu çalıştır
    PGPASSWORD="$PASSWORD" psql -U $POSTGRES_USER -h "$SQL_IP" -d $POSTGRES_USER -c "$SQL_COMMAND" \
    && echo "Komut başarıyla çalıştırıldı." || echo "Komut çalıştırılırken bir hata oluştu."
}

# Bu fonksiyon, belirtilen tabloyu sorgular ve çıktısını ekrana yazdırır.
sql_select_data() {
    local TABLE_NAME=${1:-"default_table"}  # Varsayılan tablo adı
    local PASSWORD=${2:-"$POSTGRES_SIFRESI"}  # Varsayılan şifre
    local SQL_IP=${3:-"10.207.80.20"}  # Varsayılan IP adresi

    # PostgreSQL komutunu çalıştır
    PGPASSWORD="$PASSWORD" psql -U $POSTGRES_USER -h "$SQL_IP" -d $POSTGRES_USER -c "
    SELECT * FROM $TABLE_NAME;
    " || echo "Tablo sorgulanırken bir hata oluştu."
}


# SQL server konteynır'ını başlatma
sql_start_container() {
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    bash $SCRIPT_DIR/../docker_scripts/docker_sql.sh "$@"
}


# SQL server konteynır'ını durdurma
sql_stop_container() {
    docker stop sql_container
}

