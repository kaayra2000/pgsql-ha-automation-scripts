#!/bin/bash
HELP_CODE=2

check_success() {
    local EXIT_CODE=$?
    local NEED_EXIT=${2:-true}    # Varsayılan değer "true"
    if [ $EXIT_CODE -eq $HELP_CODE ]; then  
        # Help komutu çalıştığında ve exit gerekli ise programı sonlandır
        if [ "$NEED_EXIT" = "true" ]; then
            exit 0
        fi
    elif [ $EXIT_CODE -ne 0 ]; then
        local HATA_ADI="${1:-"Bir hata oluştu. Program sonlandırılıyor."}"
        echo "$HATA_ADI"
        exit 1
    fi
    return $EXIT_CODE
}

# IP adres formatını kontrol et
validate_ip() {
    local ip=$1
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ ! $ip =~ $ip_regex ]]; then
        echo "Hata: Geçersiz IP adresi formatı: $ip"
        exit 1
    fi
}

# Port numarası kontrolü
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Hata: Geçersiz port numarası: $port"
        exit 1
    fi
}

# Sayısal değer kontrolü için fonksiyon
validate_number() {
    local value="$1"
    local param_name="$2"
    local min_value="${3:-0}"  # Opsiyonel minimum değer, varsayılan 0
    
    if [[ ! $value =~ ^[0-9]+$ ]]; then
        echo "Hata: $param_name sayısal bir değer olmalıdır"
        return 1
    fi
    
    if (( value < min_value )); then
        echo "Hata: $param_name değeri $min_value'dan büyük olmalıdır"
        return 1
    fi
    
    return 0
}

# Dizin kontrolü ve oluşturma fonksiyonu
check_directory() {
    local dir_path="$1"
    local create_if_missing="${2:-true}"  # Opsiyonel parametre, varsayılan true
    
    if [[ ! -d "$dir_path" ]]; then
        if [[ "$create_if_missing" == "true" ]]; then
            echo "Uyarı: $dir_path dizini mevcut değil, oluşturuluyor..."
            sudo mkdir -p "$dir_path"
            if [[ $? -ne 0 ]]; then
                echo "Hata: $dir_path dizini oluşturulamadı"
                return 1
            fi
            echo "$dir_path dizini başarıyla oluşturuldu"
        else
            echo "Hata: $dir_path dizini mevcut değil"
            return 1
        fi
    fi
    
    # Dizine yazma izni kontrolü
    if [[ ! -w "$dir_path" ]]; then
        echo "Hata: $dir_path dizinine yazma izni yok"
        return 1
    fi
    
    return 0
}

set_permissions() {
    # Argüman sayısını kontrol et
    if [ "$#" -lt 3 ]; then
        echo "Hata: Eksik parametre"
        echo "Kullanım: izin_ver <kullanıcı> <dosya_veya_dizin> <izin_numarası>"
        return 1
    fi

    local kullanici="$1"
    local hedef="$2"
    local izin="$3"

    # Kullanıcının varlığını kontrol et
    if ! id "$kullanici" >/dev/null 2>&1; then
        echo "Hata: $kullanici kullanıcısı mevcut değil"
        return 1
    fi

    # Dosya veya dizinin varlığını kontrol et
    if [ ! -e "$hedef" ]; then
        echo "Hata: $hedef bulunamadı"
        return 1
    fi

    # İzinleri değiştir
    if ! chmod "$izin" "$hedef"; then
        echo "Hata: İzinler değiştirilemedi"
        return 1
    fi

    # Sahipliği değiştir
    if ! chown "$kullanici:$kullanici" "$hedef"; then
        echo "Hata: Sahiplik değiştirilemedi"
        return 1
    fi

    echo "Başarılı: $hedef için izinler ve sahiplik güncellendi"
    echo "Yeni sahip: $kullanici"
    echo "Yeni izinler: $izin"
    ls -l "$hedef"
    return 0
}


check_user_exists() {
    # Argüman sayısını kontrol et
    if [ "$#" -ne 1 ]; then
        echo "Error: Missing username parameter"
        echo "Usage: check_user_exists <username>"
        return 1
    fi

    local username="$1"

    # Kullanıcı varlığını kontrol et
    if id "$username" >/dev/null 2>&1; then
        echo "Success: User '$username' exists"
        echo "User details:"
        id "$username"
        return 0
    else
        echo "Error: User '$username' does not exist"
        return 1
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
    check_success "Yapılandırma dosyası oluşturulurken bir hata oluştu."
    # Yapılandırmayı uygula
    sudo netplan apply
    check_success "Yapılandırma uygulanırken bir hata oluştu."
}

# Postgresql repository ve anahtarlarını ekle
sql_kur() {
    # PostgreSQL GPG anahtarını güvenilir anahtarlar listesine ekle
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    check_success "PostgreSQL repository eklenirken bir hata oluştu."

    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    check_success "PostgreSQL anahtarları eklenirken bir hata oluştu."

    sudo apt-get update
    check_success "Paket listesi güncellenirken bir hata oluştu."

    sudo apt -y install postgresql-15 postgresql-server-dev-15
    check_success "PostgreSQL kurulurken bir hata oluştu."

    sudo ln -s /usr/lib/postgresql/15/bin/* /usr/sbin/
    check_success "PostgreSQL 15 komutları için sembolik link oluşturulurken bir hata oluştu."
}

patroni_kur() {
    echo "Gerekli sistem paketlerini yüklüyor..."
    sudo apt update && sudo apt install -y python3 python3-pip python3-dev libpq-dev
    check_success "Gerekli sistem paketleri kurulurken bir hata oluştu."

    echo "Pip ve diğer Python bağımlılıklarını güncelliyor..."
    sudo -H pip3 install --upgrade pip setuptools wheel testresources
    check_success "Pip ve bağımlılıkları güncellenirken bir hata oluştu."

    echo "psycopg2 ve Patroni'yi yüklüyor..."
    sudo -H pip3 install psycopg2-binary patroni[etcd]
    check_success "psycopg2 veya Patroni kurulurken bir hata oluştu."

    echo "Patroni paketini yüklüyor..."
    sudo apt install -y patroni
    check_success "Patroni kurulurken bir hata oluştu."

}

# PostgreSQL konfigürasyonu yap
sql_kullanici_olustur() {
    # PostgreSQL superuser (postgres) şifresini değiştir
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$POSTGRES_SIFRESI';"
    check_success "PostgreSQL superuser (postgres) şifresi değiştirilirken bir hata oluştu."

    # Yeni kullanıcı oluştur
    sudo -u postgres psql -c "DROP ROLE $REPLIKATOR_KULLANICI_ADI;"
    sudo -u postgres psql -c "CREATE USER $REPLIKATOR_KULLANICI_ADI WITH ENCRYPTED PASSWORD '$REPLICATOR_SIFRESI';"
    check_success "PostgreSQL kullanıcısı oluşturulurken bir hata oluştu."
}

# Patroni konfigürasyonu yap
patroni_konfigure_et() {
    local node1_ip="$1"
    local node2_ip="$2"
    local node_adi="$3"
    local ETCD_IP="$4"
    patroni_yml_konfigure_et $node1_ip $node2_ip $node_adi $ETCD_IP

    sudo mkdir -p /data/patroni
    check_success "Patroni için dizin oluşturulurken bir hata oluştu."

    sudo chown -R postgres:postgres /data/
    check_success "Dizin sahipliği değiştirilirken bir hata oluştu."

    sudo chmod -R 700 /data/patroni
    check_success "Dizin izinleri değiştirilirken bir hata oluştu."

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
    check_success "Patroni konfigürasyonu yapılırken bir hata oluştu."
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
    check_success "Patroni servis dosyası oluşturulurken bir hata oluştu."
}
postgres_patroniye_devret() {
    sudo systemctl stop postgresql.service
    check_success "PostgreSQL servisi durdurulurken bir hata oluştu."
    sudo systemctl daemon-reload
    check_success "Sistem servisleri yeniden yüklenirken bir hata oluştu."
    sudo systemctl enable patroni
    check_success "Patroni servisi etkinleştirilirken bir hata oluştu."
    sudo systemctl enable postgresql
    check_success "PostgreSQL servisi etkinleştirilirken bir hata oluştu."
    sudo systemctl start patroni
    check_success "Patroni servisi başlatılırken bir hata oluştu."
    sudo systemctl start postgresql
    check_success "PostgreSQL servisi başlatılırken bir hata oluştu."
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
    check_success "Yapılandırma dosyası oluşturulurken bir hata oluştu."
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
    check_success "Yapılandırma dosyası oluşturulurken bir hata oluştu."
    # Yapılandırmayı uygula
    sudo netplan apply
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
