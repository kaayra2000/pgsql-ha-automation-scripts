#!/bin/bash

<<COMMENT
    Buradaki değişkenler arguments.cfg dosyasından okunacak.
COMMENT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source $SCRIPT_DIR/../general_functions.sh


patroni_bootstrap_dosyasi_olustur() {
    # Admin kullanıcısını oluşturacak SQL betiği
    cat <<EOF > $BOOTSTRAP_SQL_FILE
CREATE USER $PATRONI_ADMIN_USER WITH PASSWORD '$PATRONI_ADMIN_PASSWORD';
ALTER USER $PATRONI_ADMIN_USER WITH SUPERUSER CREATEDB CREATEROLE REPLICATION;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $PATRONI_ADMIN_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $PATRONI_ADMIN_USER;
EOF

    check_success "Admin kullanıcı SQL betiği oluşturulurken hata oluştu."
    
    # SQL betiğinin çalıştırılması için post_bootstrap içeriğini oluştur
    chmod 600 $BOOTSTRAP_SQL_FILE
    chown postgres:postgres $BOOTSTRAP_SQL_FILE
}

# Patroni yapılandırma dosyasını oluşturma fonksiyonu
patroni_yml_konfigure_et() {
    cat <<EOF | sudo tee /etc/patroni.yml
scope: postgres
namespace: /db/
name: $PATRONI_NODE_NAME

restapi:
    listen: 0.0.0.0:${HAPROXY_PORT}
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

    # Admin kullanıcısı oluşturma betiğini ekle
    post_bootstrap: "psql -f $BOOTSTRAP_SQL_FILE"

    pg_hba:
        - host replication $REPLIKATOR_KULLANICI_ADI 127.0.0.1/32 md5
        - host replication $REPLIKATOR_KULLANICI_ADI ${NODE1_IP}/0 md5
        - host replication $REPLIKATOR_KULLANICI_ADI ${NODE2_IP}/0 md5
        - host all all 0.0.0.0/0 md5

postgresql:
    listen: 0.0.0.0:${PGSQL_PORT}
    connect_address: ${NODE1_IP}:${PGSQL_PORT}
    data_dir: /data/patroni
    bin_dir: /usr/lib/postgresql/16/bin
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
    if [ -z "$HAPROXY_PORT" ]; then
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
        if curl -s "http://127.0.0.1:${HAPROXY_PORT}/patroni" >/dev/null 2>&1; then
            echo "Patroni API aktif ve sağlıklı (port: ${HAPROXY_PORT})"
            return 0
        else
            echo "UYARI: Patroni servisi çalışıyor fakat API şu anlık yanıt vermiyor (port: ${HAPROXY_PORT})"
            return 0
        fi
    else
        echo "HATA: Patroni servisi başlatılamadı!"
        service patroni status
        return 1
    fi
}