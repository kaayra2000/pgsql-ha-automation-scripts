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
# retry_timeout: eğer 0 olursa etcd ile bağlantı kaybedilse bile master, master kalmaya devam eder.
patroni_yml_konfigure_et() {
    if [ "$IS_NODE_1" = true ]; then
        PATRONI_NODE_NAME=$PATRONI_NODE1_NAME
        NODE_IP=$NODE1_IP
    else
        PATRONI_NODE_NAME=$PATRONI_NODE2_NAME
        NODE_IP=$NODE2_IP
    fi
    cat <<EOF | sudo tee /etc/patroni.yml
scope: postgres
namespace: /db/
name: $PATRONI_NODE_NAME

restapi:
    listen: 0.0.0.0:${HAPROXY_PORT}
    connect_address: ${NODE_IP}:${HAPROXY_PORT}

etcd:
    host: ${ETCD_IP}:${ETCD_CLIENT_PORT}

bootstrap:
    dcs:
        ttl: 30
        loop_wait: 10
        retry_timeout: 0            # etcd ile bağlantı kaybedilse bile master, master kalmaya devam eder.
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
    connect_address: ${NODE_IP}:${PGSQL_PORT}
    data_dir: $POSTGRES_DATA_DIR
    bin_dir: $POSTGRES_BIN_DIR
    pgpass: /tmp/pgpass
    authentication:
        replication:
            username: $REPLIKATOR_KULLANICI_ADI
            password: '$REPLICATOR_SIFRESI'
        superuser:
            username: postgres
            password: '$POSTGRES_SIFRESI'
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

    echo "Patroni servisi başlatılıyor..."
    service patroni start

    # Servis durumunu kontrol et
    if service patroni status >/dev/null 2>&1; then
        echo "Patroni servisi başarıyla çalışıyor."
        return 0
    else
        echo "HATA: Patroni servisi başlatılamadı!"
        service patroni status
        return 1
    fi
}

# patroni'nin servis dosyasını oluştur
setup_patroni_service() {
    local INIT_SCRIPT_PATH="/etc/init.d/patroni"
    sudo tee $INIT_SCRIPT_PATH > /dev/null << EOM
#!/bin/sh
### BEGIN INIT INFO
# Provides:          patroni
# Required-Start:    \$network \$remote_fs \$syslog
# Required-Stop:     \$network \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Patroni PostgreSQL High Availability
# Description:       Control the Patroni service for PostgreSQL
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Patroni PostgreSQL High Availability"
NAME=patroni
DAEMON="$PATRONI_BINARY_PATH"
DAEMON_ARGS="$PATRONI_YML_PATH"
PIDFILE=/var/run/\$NAME.pid
SCRIPTNAME=/etc/init.d/\$NAME

# Patroni'nin bulunduğu yolu kontrol edin
[ -x "\$DAEMON" ] || exit 0

# Gerekli fonksiyonları dahil edin
. /lib/init/vars.sh
. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting \$DESC" "\$NAME"
    start-stop-daemon --start --quiet --background --pidfile \$PIDFILE --make-pidfile --user postgres --chuid postgres --exec \$DAEMON -- \$DAEMON_ARGS
    log_end_msg \$?
    ;;
  stop)
    log_daemon_msg "Stopping \$DESC" "\$NAME"
    start-stop-daemon --stop --quiet --pidfile \$PIDFILE --name \$NAME
    log_end_msg \$?
    ;;
  restart|force-reload)
    \$0 stop
    \$0 start
    ;;
  status)
    status_of_proc -p \$PIDFILE "\$DAEMON" "\$NAME" && exit 0 || exit \$?
    ;;
  *)
    echo "Usage: \$SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
    exit 3
    ;;
esac

exit 0
EOM

    sudo chmod +x $INIT_SCRIPT_PATH
}