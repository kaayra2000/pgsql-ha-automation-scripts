#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../general_functions.sh

# Patroni yapılandırma dosyasını oluşturma fonksiyonu
patroni_yml_konfigure_et() {
    cat <<EOF | sudo tee /etc/patroni.yml
scope: postgres
namespace: /db/
name: $PATRONI_NODE_NAME

restapi:
    listen: ${NODE1_IP}:${HAPROXY_PORT}
    connect_address: ${NODE1_IP}:${HAPROXY_PORT}

etcd:
    host: ${ETCD_IP}:${ETCD_CLIENT_PORT}

bootstrap:
    dcs:
        ttl: 30
        loop_wait: 10
        retry_timeout: 10
        maximum_lag_on_failover: 1048576
        postgresql:
            use_pg_rewind: true
            use_slots: true
        parameters:
            archive_mode: true
            archive_command: 'pgbackrest --stanza=dbmaster_cls archive-push %p && cp -i %p /var/lib/pgsql/archive/%f'

    initdb:
        - encoding: UTF8
        - data-checksums

    pg_hba:
        - host replication $REPLIKATOR_KULLANICI_ADI 127.0.0.1/32 md5
        - host replication $REPLIKATOR_KULLANICI_ADI ${NODE1_IP}/0 md5
        - host replication $REPLIKATOR_KULLANICI_ADI ${NODE2_IP}/0 md5
        - host all all 0.0.0.0/0 md5

    users:
        admin:
            password: admin
            options:
                - createrole
                - createdb

postgresql:
    listen: ${NODE1_IP}:${PGSQL_PORT}
    connect_address: ${NODE1_IP}:${PGSQL_PORT}
    data_dir: /data/patroni
    bin_dir: /usr/pgsql-16/bin
    pgpass: /tmp/pgpass
    authentication:
        replication:
            username: $REPLIKATOR_KULLANICI_ADI
            password: $REPLICATOR_SIFRESI
        superuser:
            username: postgres
            password: $POSTGRES_SIFRESI
    create_replica_methods:
        - basebackup
        - pgbackrest
    pgbackrest:
        command: pgbackrest --stanza=dbmaster_cls restore --type=none
        keep_data: True
        no_params: True
    basebackup:
        checkpoint: 'fast'
        max-rate: '100M'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
EOF

    check_success "Patroni konfigürasyonu yapılırken bir hata oluştu."
}

patroni_etkinlestir() {
    local PATRONI_PORT="$1"
    if [ -z "$PATRONI_PORT" ]; then
        echo "HATA: Port numarası belirtilmedi!"
        return 1
    fi

    echo "Patroni servisi durduruluyor..."
    service patroni stop

    echo "Patroni servisi başlatılıyor..."
    service patroni start

    # Servis durumunu kontrol et
    if service patroni status >/dev/null 2>&1; then
        echo "Patroni servisi başarıyla çalışıyor."
        # API'nin çalışıp çalışmadığını kontrol et
        if curl -s "http://127.0.0.1:${PATRONI_PORT}/patroni" >/dev/null 2>&1; then
            echo "Patroni API aktif ve sağlıklı (port: ${PATRONI_PORT})"
            return 0
        else
            echo "UYARI: Patroni servisi çalışıyor fakat API şu anlık yanıt vermiyor (port: ${PATRONI_PORT})"
            return 0
        fi
    else
        echo "HATA: Patroni servisi başlatılamadı!"
        service patroni status
        return 1
    fi
}