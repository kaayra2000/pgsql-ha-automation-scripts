# postgres-ha-infrastructure

Bu depo temel olarak PostgreSQL'in yüksek erişilebilirlik mimarisini ve dns sunucusunun yine yüksek erişilebilirlik mimarisini shell scriptler ile otomatik olarak oluşturmayı hedeflemektedir. İçerisinde haproxy, etcd, patroni, keepalived, postgresql ve bind9 servislerini barındırmaktadır. Bu servislerin bir kısmı docker konteynırlarında çalıştırılmaktadır.

# Dosya içerikleri

Her klasörün içinde `README.md` dosyası bulunmaktadır. Bu dosyalar, klasördeki dosyaların ne işe yaradığını, ne içerdiğini, nasıl kullanıldığını ve notlarını içermektedir. Bu dosyaları okuyarak ilgili klasördeki dosyalar hakkında bilgi sahibi olabilirsiniz.

<details>

<summary><strong>argument_parser.sh</strong></summary>

Bu script, sabitleri ve verilen argümanları parse eder ve kullanıcının vermediği argümanlara varsayılan değerler atar. Sonuç olarak, bu argümanlar diğer dosyalarda kullanılmak üzere `arguments.cfg` dosyasına yazılır. İki durum söz konusudur:

### Durumlar

1. **_arguments.cfg_ dosyası yoksa**: Kullanıcının vermediği argümanlar yerine varsayılan değerler atanır.
2. **_arguments.cfg_ dosyası varsa**: Kullanıcının vermediği argümanlar değiştirilmeden dosyada aynen kalır. Eğer dosyada eksik argümanlar varsa, eksik olan argümanlar varsayılan değerlerle doldurulur.

### 2. Durum İçin Örnek Senaryo

Dosyanın içeriği şu şekilde olsun:

```bash
SQL_VIRTUAL_IP=10.207.80.10
DNS_VIRTUAL_IP=10.207.80.11
```
Parser'a şu argümanlar verildiğinde:

```bash
./argument_parser.sh --sql-virtual-ip 10.207.90.21
```
Dosyanın içeriği şu şekilde olacaktır:

```bash
SQL_VIRTUAL_IP=10.207.90.21
DNS_VIRTUAL_IP=10.207.80.11
NODE2_IP=10.207.80.11
REPLIKATOR_KULLANICI_ADI=replicator
IS_NODE_1=true
ETCD_CLUSTER_KEEPALIVED_STATE=new
HAPROXY_BIND_PORT=7000
ETCD_HEARTBEAT_INTERVAL=1000
ETCD_NAME=etcd1
POSTGRES_SIFRESI=postgres_pass
DNS_DOCKER_FORWARD_PORT=7777
ETCD_CLIENT_PORT=2379
KEEPALIVED_INTERFACE=enp0s3
ETCD_IP=10.207.80.20
ETCD_CLUSTER_TOKEN=cluster1
PGSQL_PORT=5432
ETCD_DATA_DIR=/var/lib/etcd/default
PGSQL_BIND_PORT=5000
ETCD_ELECTION_TIMEOUT=5000
ETCD_PEER_PORT=2380
KEEPALIVED_STATE=BACKUP
HAPROXY_PORT=8008
REPLICATOR_SIFRESI=replicator_pass
NODE1_IP=10.207.80.10
DNS_PORT=53
SQL_CONTAINER_NAME=sql_container
KEEPALIVED_PRIORITY=100
DNS_CONTAINER_NAME=dns_container
PATRONI_NODE1_NAME=pg_node1
PATRONI_NODE2_NAME=pg_node2
SQL_DOCKERFILE_NAME=docker_sql
SQL_IMAGE_NAME=sql_image
HAPROXY_SCRIPT_FOLDER=haproxy_scripts
HAPROXY_SCRIPT_NAME=create_haproxy.sh
ETCD_SCRIPT_FOLDER=etcd_scripts
ETCD_SCRIPT_NAME=create_etcd.sh
DOCKERFILE_PATH=../docker_files
DNS_DOCKERFILE_NAME=docker_dns
DNS_IMAGE_NAME=dns_image
DNS_SHELL_SCRIPT_NAME=create_dns_server.sh
ETCD_CONFIG_DIR=/etc/etcd
ETCD_CONFIG_FILE=$ETCD_CONFIG_DIR/etcd.conf.yml
ETCD_USER=etcd
POSTGRES_DATA_DIR=/var/lib/pgsql/16/data
POSTGRES_BIN_DIR=/usr/pgsql-16/bin
POSTGRES_USER=postgres
BOOTSTRAP_SQL_FILE=/var/lib/postgresql/patroni_bootstrap.sql
```
Bu durumda _SQL\_VIRTUAL\_IP_ kullanıcının verdiği değerle değişmiştir. Halihazırda dosyada mevcut olan _DNS\_VIRTUAL\_IP_ argümanı değişmemiştir. Dosyada olmayan argümanlar ise varsayılan değerlerle doldurulmuştur.

</details>

<details>

<summary><strong>general_functions.sh</strong></summary>

Bu script, diğer bash scriptlerinde kullanılmak üzere genel amaçlı yardımcı fonksiyonları içerir. Bu fonksiyonlar, argümanların kontrolü, IP ve port doğrulama, izin ayarlama, kullanıcı varlığını kontrol etme ve yardım mesajları gösterme gibi işlemleri kolaylaştırır.

### Fonksiyonlar

#### parse_and_read_arguments

```bash
parse_and_read_arguments() {
    # Argümanları parçalar, dosyaya yazar ve dosyadan okur
}
```
* **Amaç:** Verilen argümanları parse ederek `_arguments.cfg_` dosyasına yazar ve dosyadan okur.

#### read_arguments

```bash
read_arguments() {
    # Argümanları dosyadan okur ve export eder
}
```
* **Amaç:** Verilen dosyadan argümanları okuyarak ortam değişkenleri olarak export eder.

#### check_success

```bash
check_success() {
    # Önceki komutun başarı durumunu kontrol eder
}
```
* **Amaç:** Önceki komutun başarılı olup olmadığını kontrol eder. Hata durumunda uygun hata mesajını gösterir ve gerekirse scriptin çalışmasını sonlandırır.

#### validate_ip

```bash
validate_ip() {
    # IP adres formatını kontrol eder
}
```

* **Amaç:** Verilen IP adresinin geçerli bir formatta olup olmadığını kontrol eder.

#### validate_port

```bash
validate_port() {
    # Port numarasının geçerli olup olmadığını kontrol eder
}
```

* **Amaç:** Verilen port numarasının 1 ile 65535 arasında geçerli bir sayı olup olmadığını kontrol eder.

#### validate_number

```bash
validate_number() {
    # Sayısal değeri kontrol eder
}
```

* **Amaç:** Verilen değerin sayısal bir değer olup olmadığını ve isteğe bağlı olarak belirli bir minimum değerden büyük olup olmadığını kontrol eder.

#### check_and_create_directory

```bash
check_and_create_directory() {
    # Dizin varlığını ve yazılabilirliğini kontrol eder
}
```

* **Amaç:** Verilen dizinin varlığını ve yazma iznini kontrol eder. Eğer dizin mevcut değilse ve izin verilmişse oluşturur.

#### set_permissions

```bash
set_permissions() {
    # Dosya veya dizin izinlerini ve sahipliğini ayarlar
}
```

* **Amaç:** Belirtilen dosya veya dizin için kullanıcıya ait izinleri ve sahipliği ayarlar.

#### check_user_exists

```bash
check_user_exists() {
    # Kullanıcının varlığını kontrol eder
}
```

* **Amaç:** Verilen kullanıcının sistemde mevcut olup olmadığını kontrol eder.

#### show_argument_help

```bash
show_argument_help() {
    # Yardım mesajını gösterir
}
```

* **Amaç:** Scriptin kullanımını ve argüman açıklamalarını formatlı bir şekilde ekrana yazdırır.

#### show_argument_help

```bash
#!/bin/bash

# general_functions.sh dosyasını dahil et
source /path/to/general_functions.sh

# Örnek fonksiyon kullanımı
validate_ip "192.168.1.1"
check_user_exists "kullaniciadi"
set_permissions "kullaniciadi" "/var/www" "755"
```

### Notlar

* Dikkat edilmesi gereken noktalar:
  * Fonksiyonlar hata durumunda genellikle bir hata mesajı yazdırır ve scriptin çalışmasını exit 1 ile sonlandırır.
  * parse_and_read_arguments fonksiyonu, argümanları dosyaya yazdığı için scriptin başında çağrılmalıdır.
  * set_permissions ve check_user_exists fonksiyonları, sistem üzerinde değişiklik yapar ve uygun yetkilere ihtiyaç duyabilir.

</details>


<details>

<summary><strong>default_variables.sh</strong></summary>

Bu script, diğer scriptlerde kullanılmak üzere varsayılan değerleri tanımlayan değişkenleri içerir. Bu değişkenler, HAProxy, PostgreSQL, Patroni, Keepalived, ETCD ve Docker ile ilgili ayarların kolayca yönetilmesini sağlar.

### Özellikler

- **HAProxy Değişkenleri**:
  - `DEFAULT_NODE1_IP`:
    - Açıklama: HAProxy'nin yönlendireceği ilk PostgreSQL düğümünün IP adresi.
    - Varsayılan Değer: `"10.207.80.10"`
  - `DEFAULT_NODE2_IP`:
    - Açıklama: HAProxy'nin yönlendireceği ikinci PostgreSQL düğümünün IP adresi.
    - Varsayılan Değer: `"10.207.80.11"`
  - `DEFAULT_HAPROXY_BIND_PORT`:
    - Açıklama: HAProxy'nin durum ve istatistik sayfasının HTTP üzerinden erişileceği port.
    - Varsayılan Değer: `"7000"`
  - `DEFAULT_PGSQL_PORT`:
    - Açıklama: Arka uç PostgreSQL düğümlerinin çalıştığı port.
    - Varsayılan Değer: `"5432"`
  - `DEFAULT_HAPROXY_PORT`:
    - Açıklama: HAProxy'nin gelen PostgreSQL bağlantıları için dinlediği port.
    - Varsayılan Değer: `"8008"`
  - `DEFAULT_PGSQL_BIND_PORT`:
    - Açıklama: HAProxy'nin PostgreSQL istemci bağlantıları için dinlediği port.
    - Varsayılan Değer: `"5000"`

- **PostgreSQL ve Patroni Değişkenleri**:
  - `DEFAULT_PATRONI_NODE1_NAME`:
    - Açıklama: Patroni küme yapılandırmasındaki birinci düğümün adı.
    - Varsayılan Değer: `"pg_node1"`
  - `DEFAULT_PATRONI_NODE2_NAME`:
    - Açıklama: Patroni küme yapılandırmasındaki ikinci düğümün adı.
    - Varsayılan Değer: `"pg_node2"`
  - `DEFAULT_ETCD_IP`:
    - Açıklama: Patroni'nin koordinasyon için kullandığı ETCD kümesinin IP adresi.
    - Varsayılan Değer: `DEFAULT_SQL_VIRTUAL_IP` değerini kullanır.
  - `DEFAULT_REPLIKATOR_KULLANICI_ADI`:
    - Açıklama: PostgreSQL replikasyon kullanıcısı için kullanıcı adı.
    - Varsayılan Değer: `"replicator"`
  - `DEFAULT_REPLICATOR_SIFRESI`:
    - Açıklama: PostgreSQL replikasyon kullanıcısı için şifre.
    - Varsayılan Değer: `"111"`
  - `DEFAULT_POSTGRES_SIFRESI`:
    - Açıklama: PostgreSQL süper kullanıcı 'postgres' için şifre.
    - Varsayılan Değer: `"111"`
  - `DEFAULT_IS_NODE_1`:
    - Açıklama: Bu düğümün kümedeki ilk düğüm olup olmadığını belirten bayrak. Bu bayrağa göre Patroni ip atamaları yapılıyor. (`true` veya `false`)
    - Varsayılan Değer: `"true"`

- **Keepalived Değişkenleri**:
  - `DEFAULT_KEEPALIVED_INTERFACE`:
    - Açıklama: Keepalived'in VRRP iletişimi için kullanacağı ağ arayüzü (örn: `eth0`).
    - Varsayılan Değer: `"enp0s3"`
  - `DEFAULT_SQL_VIRTUAL_IP`:
    - Açıklama: Keepalived tarafından yönetilen PostgreSQL servisi için sanal IP adresi.
    - Varsayılan Değer: `"10.207.80.20"`
  - `DEFAULT_DNS_VIRTUAL_IP`:
    - Açıklama: Keepalived tarafından yönetilen DNS servisi için sanal IP adresi.
    - Varsayılan Değer: `"10.207.80.30"`
  - `DEFAULT_KEEPALIVED_PRIORITY`:
    - Açıklama: Keepalived için öncelik değeri; daha yüksek değer, master seçiminde daha yüksek öncelik anlamına gelir (tamsayı).
    - Varsayılan Değer: `"100"`
  - `DEFAULT_KEEPALIVED_STATE`:
    - Açıklama: Düğümün Keepalived VRRP içindeki başlangıç durumu (`"MASTER"` veya `"BACKUP"`).
    - Varsayılan Değer: `"BACKUP"`
  - `DEFAULT_SQL_CONTAINER_NAME`:
    - Açıklama: Keepalived'in izlediği SQL (PostgreSQL) konteynerinin adı.
    - Varsayılan Değer: `"sql_container"`
  - `DEFAULT_DNS_CONTAINER_NAME`:
    - Açıklama: Keepalived'in izlediği DNS konteynerinin adı.
    - Varsayılan Değer: `"dns_container"`

- **DNS Argümanları**:
  - `DEFAULT_DNS_PORT`:
    - Açıklama: DNS servisi için dinleme portu.
    - Varsayılan Değer: `"53"`
  - `DEFAULT_DNS_DOCKER_FORWARD_PORT`:
    - Açıklama: DNS Docker konteynerine yönlendirilecek ana makine portu.
    - Varsayılan Değer: `"7777"`

- **ETCD Varsayılan Değerleri**:
  - `DEFAULT_ETCD_IP`:
    - Açıklama: ETCD'nin IP adresi.
    - Varsayılan Değer: `DEFAULT_SQL_VIRTUAL_IP` değerini kullanır.
  - `DEFAULT_ETCD_CLIENT_PORT`:
    - Açıklama: ETCD istemci portu.
    - Varsayılan Değer: `"2379"`
  - `DEFAULT_ETCD_PEER_PORT`:
    - Açıklama: ETCD eşler arası iletişim portu.
    - Varsayılan Değer: `"2380"`
  - `DEFAULT_ETCD_CLUSTER_TOKEN`:
    - Açıklama: ETCD kümesini benzersiz bir şekilde tanımlayan token değeri.
    - Varsayılan Değer: `"cluster1"`
  - `DEFAULT_ETCD_CLUSTER_KEEPALIVED_STATE`:
    - Açıklama: ETCD kümesinin başlangıç durumu (`"new"` için ilk kurulum veya `"existing"` düğüm ekleme).
    - Varsayılan Değer: `"new"`
  - `DEFAULT_ETCD_NAME`:
    - Açıklama: Bu ETCD düğümünün küme içindeki adı.
    - Varsayılan Değer: `"etcd1"`
  - `DEFAULT_ETCD_ELECTION_TIMEOUT`:
    - Açıklama: ETCD seçim zaman aşımı değeri (milisaniye cinsinden).
    - Varsayılan Değer: `"5000"`
  - `DEFAULT_ETCD_HEARTBEAT_INTERVAL`:
    - Açıklama: ETCD kalp atışı aralığı (milisaniye cinsinden).
    - Varsayılan Değer: `"1000"`
  - `DEFAULT_ETCD_DATA_DIR`:
    - Açıklama: ETCD verilerinin saklanacağı dizin.
    - Varsayılan Değer: `"/var/lib/etcd/default"`

- **Docker Değişkenleri**:
  - `SHELL_PATH_IN_DOCKER`:
    - Açıklama: Docker konteyner içinde shell komutlarının bulunduğu dizin.
    - Varsayılan Değer: `"/usr/local/bin"`

### Kullanım

Bu değişkenler, diğer scriptlerde varsayılan değerleri atamak için kullanılır. Eğer kullanıcı tarafından bir değer belirtilmemişse, ilgili değişken bu dosyadaki varsayılan değeri alır. Böylece, sistem yapılandırması daha tutarlı ve yönetilebilir hale gelir.

### Notlar

- Değişken isimleri büyük harflerle ve `DEFAULT_` önekiyle tanımlanmıştır.
- `DEFAULT_ETCD_IP` değişkeni, `DEFAULT_SQL_VIRTUAL_IP` değerini kullanarak ETCD IP adresini otomatik olarak ayarlar.
- Bu dosya, sistem yöneticilerinin varsayılan ayarları merkezi bir yerden kontrol etmelerini sağlar.
- İhtiyaç duyulması halinde, bu varsayılan değerler güncellenebilir veya genişletilebilir.

</details>



# DNS Sunucusu Kurma
``create_dns_server.sh`` scripti, DNS sunucusunu başlatmak için kullanılır.`arguments.cfg` dosyasındaki değişkenleri ve `dns_setup.sh` dosyasındaki fonksiyonları kullanarak dns kurulumunu yapar.

## Ne işe yarar?

Bu dosyaların amacı docker üzerinde otomatik dns kurulabilmesine vesile olmaktır. `docker_scripts/docker_dns.sh` dosyası bu klasördeki dosyaları kullanır.


## Nasıl kullanılır?

Normal şartlarda `docker_scripts/docker_dns.sh` dosyası bu dosyaları kullanarak dns kurulumunu yapar. Ancak bu dosyaları tek başına çalıştırmak isterseniz aşağıdaki komutu çalıştırabilirsiniz.

```bash
./create_dns_server.sh
```

Eğer hangi argümanları alabildiğini öğrenmek istiyorsanız aşağıdaki komutları çalıştırabilirsiniz.

```bash
./create_dns_server.sh -h
```
```bash
./create_dns_server.sh --help
```

Örnek bir kullanım:

```bash
./create_dns_server.sh --dns-port 53 --dns-docker-forward-port 7777 
```

## Not

- Eğer argümanları teker teker geçirmek istemiyorsanız `arguments.cfg` dosyasını düzenleyerek `create_dns_server.sh` dosyasını çalıştırabilirsiniz. Zaten varsayılan olarak oradaki değerler alınacaktır.

- Eğer argümanları yukarıdaki örnekteki gibi geçirirseniz `create_dns_server.sh` dosyası `arguments.cfg` dosyasındaki değerleri değiştirecektir. Bu durumda, ilk geçirdiğiniz değerleri tekrar geçirmek istiyorsanız, bir daha argümanaları yukarıdaki örnekteki gibi geçirmenize gerek yoktur.

- `arguments.cfg` dosyasında bu `create_dns_server.sh` dosyasında kullanılmayan argümanlar da bulunmaktadır. Tüm ***komut*** (.sh) dosyalarının argümanları tek bir merkezde toplandığı için bu durum normaldir. Eğer sadece `create_dns_server.sh` komut dosyasını çalıştıracaksanız `arguments.cfg` dosyasındaki fazlalık argümanları umursamayın.