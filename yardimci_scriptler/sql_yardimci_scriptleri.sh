#!/bin/bash


# Docker konteynırında çalışan patroni servisinin loglarını getirme
get_patroni_log() {
    docker exec sql_container /bin/bash -c "cat /var/log/patroni/patroni.log"
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

# SQL server'a bağlanabilmek için
connect_sql_server() {
    local SQL_IP=${1:-"10.207.80.20"}
    psql -U postgres -h $SQL_IP
}