#!/bin/bash

hata_kontrol() {
    local HATA_ADI="${1:-"Bir hata oluştu. Program sonlandırılıyor."}"
    if [ $? -ne 0 ]; then
        echo "$HATA_ADI"
        exit 1
    fi
}

ip_sifirla() {
    echo "network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s3:
      dhcp4: true" | sudo tee "/etc/netplan/01-network-manager-all.yaml"
    sudo chmod 600 /etc/netplan/01-network-manager-all.yaml
    hata_kontrol "Yapılandırma dosyası oluşturulurken bir hata oluştu."
    # Yapılandırmayı uygula
    sudo netplan apply
    hata_kontrol "Yapılandırma uygulanırken bir hata oluştu."
}

# Postgresql repository ve anahtarlarını ekle
sql_kur() {
    # PostgreSQL GPG anahtarını güvenilir anahtarlar listesine ekle
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    hata_kontrol "PostgreSQL repository eklenirken bir hata oluştu."

    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    hata_kontrol "PostgreSQL anahtarları eklenirken bir hata oluştu."

    sudo apt-get update
    hata_kontrol "Paket listesi güncellenirken bir hata oluştu."

    sudo apt -y install postgresql-15 postgresql-server-dev-15
    hata_kontrol "PostgreSQL kurulurken bir hata oluştu."

    sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/
    hata_kontrol "PostgreSQL 15 komutları için sembolik link oluşturulurken bir hata oluştu."
}

patroni_kur() {
    echo "Gerekli sistem paketlerini yüklüyor..."
    sudo apt update && sudo apt install -y python3 python3-pip python3-dev libpq-dev
    hata_kontrol "Gerekli sistem paketleri kurulurken bir hata oluştu."

    echo "Pip ve diğer Python bağımlılıklarını güncelliyor..."
    sudo -H pip3 install --upgrade pip setuptools wheel testresources
    hata_kontrol "Pip ve bağımlılıkları güncellenirken bir hata oluştu."

    echo "psycopg2 ve Patroni'yi yüklüyor..."
    sudo -H pip3 install psycopg2-binary patroni[etcd]
    hata_kontrol "psycopg2 veya Patroni kurulurken bir hata oluştu."

    echo "Patroni paketini yüklüyor..."
    sudo apt install -y patroni
    hata_kontrol "Patroni kurulurken bir hata oluştu."

}

# PostgreSQL konfigürasyonu yap
sql_kullanici_olustur() {
    # PostgreSQL superuser (postgres) şifresini değiştir
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$POSTGRES_SIFRESI';"
    hata_kontrol "PostgreSQL superuser (postgres) şifresi değiştirilirken bir hata oluştu."

    # Yeni kullanıcı oluştur
    sudo -u postgres psql -c "DROP ROLE $REPLIKATOR_KULLANICI_ADI;"
    sudo -u postgres psql -c "CREATE USER $REPLIKATOR_KULLANICI_ADI WITH ENCRYPTED PASSWORD '$REPLICATOR_SIFRESI';"
    hata_kontrol "PostgreSQL kullanıcısı oluşturulurken bir hata oluştu."
}

# Patroni konfigürasyonu yap
patroni_konfigure_et() {
    local node1_ip="$1"
    local node2_ip="$2"
    local node_adi="$3"
    local ETCD_IP="$4"
    patroni_yml_konfigure_et $node1_ip $node2_ip $node_adi $ETCD_IP

    sudo mkdir -p /data/patroni
    hata_kontrol "Patroni için dizin oluşturulurken bir hata oluştu."

    sudo chown -R postgres:postgres /data/
    hata_kontrol "Dizin sahipliği değiştirilirken bir hata oluştu."

    sudo chmod -R 700 /data/patroni
    hata_kontrol "Dizin izinleri değiştirilirken bir hata oluştu."

    patroni_servis_olustur
}
# Patroni yml dosyasını konfigure et
patroni_yml_konfigure_et() {
    local node1_ip="$1"
    local node2_ip="$2"
    local node_adi="$3"
    local ETCD_IP="$4"
    cat <<EOF | sudo tee /etc/patroni.yml
scope: postgres
namespace: /db/
name: $node_adi

restapi:
    listen: ${node1_ip}:$HAPROXY_PORT
    connect_address: ${node1_ip}:$HAPROXY_PORT

etcd:
    host: ${ETCD_IP}:$ETCD_PORT_0

bootstrap:
    dcs:
        ttl: 30
        loop_wait: 10
        retry_timeout: 10
        maximum_lag_on_failover: 1048576
        postgresql:
            use_pg_rewind: true

    initdb:
    - encoding: UTF8
    - data-checksums

    pg_hba:
    - host replication $REPLIKATOR_KULLANICI_ADI 127.0.0.1/32 md5
    - host replication $REPLIKATOR_KULLANICI_ADI ${node1_ip}/0 md5
    - host replication $REPLIKATOR_KULLANICI_ADI ${node2_ip}/0 md5
    - host all all 0.0.0.0/0 md5

    users:
        admin:
            password: admin
            options:
                - createrole
                - createdb

postgresql:
    listen: ${node1_ip}:$PGSQL_PORT
    connect_address: ${node1_ip}:$PGSQL_PORT
    data_dir: /data/patroni
    pgpass: /tmp/pgpass
    authentication:
        replication:
            username: $REPLIKATOR_KULLANICI_ADI
            password: $REPLICATOR_SIFRESI
        superuser:
            username: postgres
            password: $POSTGRES_SIFRESI
    parameters:
        unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
EOF
    hata_kontrol "Patroni konfigürasyonu yapılırken bir hata oluştu."
}

# Patroni servis dosyasını oluştur
patroni_servis_olustur() {
    cat <<EOF | sudo tee /etc/systemd/system/patroni.service
[Unit]
Description=Runners to orchestrate a high-availability PostgreSQL
After=syslog.target network.target

[Service]
Type=simple

User=postgres
Group=postgres

ExecStart=/usr/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.target
EOF
    hata_kontrol "Patroni servis dosyası oluşturulurken bir hata oluştu."
}
postgres_patroniye_devret() {
    sudo systemctl stop postgresql.service
    hata_kontrol "PostgreSQL servisi durdurulurken bir hata oluştu."
    sudo systemctl daemon-reload
    hata_kontrol "Sistem servisleri yeniden yüklenirken bir hata oluştu."
    sudo systemctl enable patroni
    hata_kontrol "Patroni servisi etkinleştirilirken bir hata oluştu."
    sudo systemctl enable postgresql
    hata_kontrol "PostgreSQL servisi etkinleştirilirken bir hata oluştu."
    sudo systemctl start patroni
    hata_kontrol "Patroni servisi başlatılırken bir hata oluştu."
    sudo systemctl start postgresql
    hata_kontrol "PostgreSQL servisi başlatılırken bir hata oluştu."
}
# Ağ arayüzüne statik IP adresi ata
statik_ip_ata() {
    local ARAYUZ="$1"
    local IP_ADRES="$2"
    local NETMASK="$3"
    local GATEWAY="$4"
    local DNS="$5"

    # Yedek yapılandırma dosyasının varlığını kontrol et
    if [ -f "/etc/netplan/01-network-manager-all.yaml.backup" ]; then
        echo "Yedek dosya zaten var."
    else
        echo "Yedek dosya bulunamadı, kopyalama yapılıyor."
        # Yedek dosyasını kopyala
        sudo cp /etc/netplan/01-network-manager-all.yaml /etc/netplan/01-network-manager-all.yaml.backup
    fi

    echo "network:
  version: 2
  renderer: NetworkManager
  ethernets:
    $ARAYUZ:
      addresses: [${IP_ADRES}/${NETMASK}]
      routes:
        - to: 0.0.0.0/0
          via: $GATEWAY
      nameservers:
        addresses: [${DNS}]" | sudo tee "/etc/netplan/01-network-manager-all.yaml"
    sudo chmod 600 /etc/netplan/01-network-manager-all.yaml
    hata_kontrol "Yapılandırma dosyası oluşturulurken bir hata oluştu."
    # Yapılandırmayı uygula
    sudo netplan apply
}

ip_sifirla() {
    echo "network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s3:
      dhcp4: true" | sudo tee "/etc/netplan/01-network-manager-all.yaml"
    sudo chmod 600 /etc/netplan/01-network-manager-all.yaml
    hata_kontrol "Yapılandırma dosyası oluşturulurken bir hata oluştu."
    # Yapılandırmayı uygula
    sudo netplan apply
}

etcd_kur() {
    sudo apt install etcd -y
    hata_kontrol "etcd kurulurken bir hata oluştu."
}

etcd_konfigure_et() {
    local ETCD_IP_ADRESI="$1"
    local ETCD_PORT_0="$2"
    local ETCD_PORT_1="$3"
    echo -n "ETCD_LISTEN_PEER_URLS=\"http://$ETCD_IP_ADRESI:$ETCD_PORT_1,http://127.0.0.1:7001\"
ETCD_LISTEN_CLIENT_URLS=\"http://127.0.0.1:$ETCD_PORT_0, http://$ETCD_IP_ADRESI:$ETCD_PORT_0\"
ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http://$ETCD_IP_ADRESI:$ETCD_PORT_1\"
ETCD_INITIAL_CLUSTER=\"default=http://$ETCD_IP_ADRESI:$ETCD_PORT_1,\"
ETCD_ADVERTISE_CLIENT_URLS=\"http://$ETCD_IP_ADRESI:$ETCD_PORT_0\"
ETCD_INITIAL_CLUSTER_TOKEN=\"cluster1\"
ETCD_INITIAL_CLUSTER_STATE=\"new\"" | sudo tee /etc/default/etcd >/dev/null
    hata_kontrol "etcd konfigürasyonu yapılırken bir hata oluştu."
}

etcd_etkinlestir() {
    sudo systemctl restart etcd
    hata_kontrol "etcd servisi başlatılırken bir hata oluştu."

    sudo systemctl enable etcd
    hata_kontrol "etcd servisi etkinleştirilirken bir hata oluştu."
}
hosts_dosyasina_yaz() {
    # Dosya yolu
    local HOSTS_FILE="/etc/hosts"

    # Argümanları değişkenlere ata
    local IP1=$1
    local IP2=$2
    local IP3=$3
    local NAME1=$4
    local NAME2=$5
    local NAME3=$6

    # Her bir giriş için kontrol yap ve ekle/güncelle
    for i in 1 2 3; do
        local IP_VAR="IP$i"
        local NAME_VAR="NAME$i"
        local IP="${!IP_VAR}"
        local NAME="${!NAME_VAR}"

        # /etc/hosts dosyasında IP ve NAME kontrolü
        if grep -qE "^$IP\s+$NAME$" "$HOSTS_FILE"; then
            echo "$IP ve $NAME zaten /etc/hosts dosyasında var."
        else
            # Mevcut IP adresinin başka bir isimle kullanılıp kullanılmadığını kontrol et
            if grep -qE "^$IP\s+" "$HOSTS_FILE"; then
                # Mevcut girişi değiştir
                sudo sed -i "s|^$IP\s+.*|$IP       $NAME|" "$HOSTS_FILE"
                echo "$IP adresi güncellendi: $NAME"
            else
                # Yeni giriş ekle
                echo "$IP       $NAME" | sudo tee -a "$HOSTS_FILE"
                echo "$IP ve $NAME /etc/hosts dosyasına eklendi."
            fi
        fi
    done
}
