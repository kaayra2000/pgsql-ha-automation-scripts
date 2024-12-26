#!/bin/bash

# SQL server'a bağlanabilmek için
connect_sql_server() {
    local SQL_IP=${1:-"10.207.80.20"}
    psql -U postgres -h $SQL_IP
}
# Docker konteynırında çalışan Patroni servisinin loglarını ekrana yazdırma
print_patroni_log() {
    docker exec sql_container /bin/bash -c "cat /var/log/patroni/patroni.log"
}

# Docker konteynırında çalışan PostgreSQL loglarını ekrana yazdırma
print_sql_log() {
    docker exec sql_container /bin/bash -c "ls -tr /var/lib/postgresql/16/data/log | while read file; do cat /var/lib/postgresql/16/data/log/\$file; done"
}

# Patroni loglarını bulunduğunuz klasöre kopyalama
get_patroni_log() {
    docker exec sql_container /bin/bash -c "cat /var/log/patroni/patroni.log" > patroni.log
    echo "Patroni logları bulunduğunuz klasöre 'patroni.log' olarak kaydedildi."
}

# PostgreSQL loglarını bulunduğunuz klasöre kopyalama
get_sql_log() {
    docker exec sql_container /bin/bash -c "ls -tr /var/lib/postgresql/16/data/log | while read file; do cat /var/lib/postgresql/16/data/log/\$file; done" > sql_logs.log
    echo "PostgreSQL logları bulunduğunuz klasöre 'sql_logs.log' olarak kaydedildi."
}

# SQL server konteynır'ını başlatma
start_sql_container() {
    local FILE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    bash $FILE_PATH/../docker_scripts/docker_sql.sh "$@"
}


# SQL server konteynır'ını durdurma
stop_sql_container() {
    docker stop sql_container
}

