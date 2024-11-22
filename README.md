# postgres-ha-infrastructure

Bu depo temel olarak PostgreSQL'in yüksek erişilebilirlik mimarisini ve dns sunucusunun yine yüksek erişilebilirlik mimarisini shell scriptler ile otomatik olarak oluşturmayı hedeflemektedir. İçerisinde haproxy, etcd, patroni, keepalived, postgresql ve bind9 servislerini barındırmaktadır. Bu servislerin bir kısmı docker konteynırlarında çalıştırılmaktadır.

# Dosya içerikleri

<details>

<summary><strong>argument_parser.sh</strong></summary>

Bu script, verilen argümanları parse eder ve kullanıcının vermediği argümanlara varsayılan değerler atar. Sonuç olarak, bu argümanlar diğer dosyalarda kullanılmak üzere `_arguments.cfg_` dosyasına yazılır. İki durum söz konusudur:

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
ELECTION_TIMEOUT=5000
NODE2_IP=10.207.80.11
REPLIKATOR_KULLANICI_ADI=replicator
PRIORITY=100
INTERFACE=et123456
IS_NODE_1=true
HAPROXY_BIND_PORT=7000
DNS_CONTAINER=dns_1
ETCD_NAME=etcd1
POSTGRES_SIFRESI=postgres_pass
ETCD_CLIENT_PORT=2379
HEARTBEAT_INTERVAL=1000
ETCD_IP=10.207.80.20
NODE_NAME=pg_node1
PGSQL_PORT=5432
CLUSTER_STATE=new
DATA_DIR=/var/lib/etcd/default
CLUSTER_TOKEN=cluster1
ETCD_PEER_PORT=2380
POSTGRES_BIND_PORT=5000
HAPROXY_PORT=8008
REPLICATOR_SIFRESI=replicator_pass
SQL_CONTAINER=sql_1
NODE1_IP=10.207.80.10
STATE=BACKUP
DNS_VIRTUAL_IP=10.207.80.11
```
Bu durumda _SQL\_VIRTUAL\_IP_ kullanıcının verdiği değerle değişmiştir. Halihazırda dosyada mevcut olan _DNS\_VIRTUAL\_IP_ argümanı değişmemiştir. Dosyada olmayan argümanlar ise varsayılan değerlerle doldurulmuştur.

</details>

<details>

<summary><strong>create_dns_server.sh</strong></summary>

Bu script, BIND9 DNS sunucusunu belirli bir port üzerinden kurar ve yapılandırır. Kullanıcıdan aldığı **port numarası** ile BIND9'un o portta dinlemesini sağlar. Ayrıca, gerekli yapılandırma dosyalarını oluşturur ve servisi yeniden başlatarak değişiklikleri uygular.

### Özellikler

- **Port Ayarı**: Kullanıcının belirttiği port numarasını kontrol ederek geçerli bir değer olup olmadığını doğrular.

- **BIND9 Kurulumu**: BIND9 ve ilgili paketleri otomatik olarak kurar.

- **Yapılandırma**:
  - `named.conf.options` dosyasını düzenleyerek DNS sunucusunun genel ayarlarını yapar.
  - `named.conf.local` dosyasını oluşturur ve zone tanımlarını ekler.
  - Örnek zone dosyaları (`db.example.com` ve `db.server`) oluşturur.

- **Servis Yönetimi**: BIND9 servisini yeniden başlatarak yeni yapılandırmaların etkin olmasını sağlar.

### Kullanım

```bash
./create_dns_server.sh <port>
```
* \<port>: DNS sunucusunun dinleyeceği port numarası (1 ile 65535 arasında geçerli bir tam sayı olmalıdır).

**Örnek:**
```bash
./create_dns_server.sh 5353
```
Bu komut, DNS sunucusunu 5353 numaralı portta çalışacak şekilde kurar ve yapılandırır.

### Notlar
* **Yetkilendirme:** Script, bazı işlemler için sudo yetkisi gerektirir.
* **Sistem Gereksinimleri:** Ubuntu/Debian tabanlı sistemlerde çalışacak şekilde tasarlanmıştır.
* **Güncellemeler:** Oluşturulan zone dosyalarını ve yapılandırma ayarlarını ihtiyaçlarınıza göre düzenleyebilirsiniz.
* **Güvenlik:** Varsayılan ayarlar tüm IP adreslerinden gelen sorgulara izin verir. Güvenlik açısından allow-query gibi ayarları düzenlemeniz önerilir.

</details>

<details>

<summary><strong>general_functions.sh</strong></summary>

Bu script, diğer bash scriptlerinde kullanılmak üzere genel amaçlı yardımcı fonksiyonları içerir. Bu fonksiyonlar, argümanların kontrolü, IP ve port doğrulama, izin ayarlama, kullanıcı varlığını kontrol etme ve yardım mesajları gösterme gibi işlemleri kolaylaştırır.

### Fonksiyonlar

#### check_and_parse_arguments

```bash
check_and_parse_arguments() {
    # Argüman dosyasının varlığını kontrol eder ve gerekli fonksiyonları çağırır
}
```
* **Amaç:** Argüman dosyasının varlığını kontrol eder. Eğer dosya yoksa, argümanları parse eder ve gerekli işlemleri yapar. Ardından, argümanları dosyadan okuyarak ortam değişkenleri olarak ayarlar.

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

#### check_directory

```bash
check_directory() {
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

#### show_help

```bash
show_help() {
    # Yardım mesajını gösterir
}
```

* **Amaç:** Scriptin kullanımını ve argüman açıklamalarını formatlı bir şekilde ekrana yazdırır.

#### show_argument_help

```bash
show_argument_help() {
    # Argüman yardımını gösterir
}
```

* **Amaç:** Argüman listesini ve açıklamalarını düzenli bir formatta kullanıcıya gösterir.

### Kullanım
Bu script, diğer scriptlerin içine dahil edilerek fonksiyonların kullanılmasını sağlar. Başka bir script içinde aşağıdaki şekilde kullanılabilir:

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
  * check_and_parse_arguments fonksiyonu, argüman dosyasının varlığını kontrol eder ve argümanları parse eder. Bu fonksiyonun doğru çalışması için gerekli parametrelerin doğru sırada ve eksiksiz verilmesi gerekir.
  * set_permissions ve check_user_exists fonksiyonları, sistem üzerinde değişiklik yapar ve uygun yetkilere ihtiyaç duyabilir.

</details>


<details>

<summary><strong>default_variables.sh</strong></summary>

Bu script, diğer scriptlerde kullanılmak üzere varsayılan değerleri tanımlayan değişkenleri içerir. Bu değişkenler, HAProxy, PostgreSQL, Patroni, Keepalived, ETCD ve Docker ile ilgili ayarların kolayca yönetilmesini sağlar.

### Özellikler

- **HAProxy Değişkenleri**:
  - `DEFAULT_NODE1_IP`: İlk node'un IP adresi. Varsayılan değer: `"10.207.80.10"`
  - `DEFAULT_NODE2_IP`: İkinci node'un IP adresi. Varsayılan değer: `"10.207.80.11"`
  - `DEFAULT_HAPROXY_BIND_PORT`: HAProxy'nin bağlanacağı port. Varsayılan değer: `"7000"`
  - `DEFAULT_HAPROXY_PORT`: HAProxy'nin dinleyeceği port. Varsayılan değer: `"8008"`

- **PostgreSQL ve Patroni Değişkenleri**:
  - `DEFAULT_NODE_NAME`: Node adı. Varsayılan değer: `"pg_node1"`
  - `DEFAULT_PGSQL_PORT`: PostgreSQL'in dinlediği port. Varsayılan değer: `"5432"`
  - `DEFAULT_POSTGRES_BIND_PORT`: PostgreSQL'in bağlanacağı port. Varsayılan değer: `"5000"`
  - `DEFAULT_REPLIKATOR_KULLANICI_ADI`: Replikasyon için kullanılacak kullanıcı adı. Varsayılan değer: `"replicator"`
  - `DEFAULT_REPLICATOR_SIFRESI`: Replikasyon kullanıcısının şifresi. Varsayılan değer: `"replicator_pass"`
  - `DEFAULT_POSTGRES_SIFRESI`: PostgreSQL veritabanı kullanıcısının şifresi. Varsayılan değer: `"postgres_pass"`
  - `DEFAULT_IS_NODE_1`: Node'un birinci node olup olmadığını belirten değer. Varsayılan değer: `"true"`

- **Keepalived Değişkenleri**:
  - `DEFAULT_INTERFACE`: Ağ arayüzü adı. Varsayılan değer: `"enp0s3"`
  - `DEFAULT_SQL_VIRTUAL_IP`: SQL için sanal IP adresi. Varsayılan değer: `"10.207.80.20"`
  - `DEFAULT_DNS_VIRTUAL_IP`: DNS için sanal IP adresi. Varsayılan değer: `"10.207.80.30"`
  - `DEFAULT_PRIORITY`: Keepalived öncelik değeri. Varsayılan değer: `"100"`
  - `DEFAULT_STATE`: Keepalived durumunu belirtir (`MASTER` veya `BACKUP`). Varsayılan değer: `"BACKUP"`
  - `DEFAULT_SQL_CONTAINER`: SQL için Docker container adı. Varsayılan değer: `"sql_container"`
  - `DEFAULT_DNS_CONTAINER`: DNS için Docker container adı. Varsayılan değer: `"dns_container"`
  - `DOCKER_BINARY_PATH`: Docker binary dosyasının yolu. Varsayılan değer: `"/usr/bin/docker"`

- **ETCD Varsayılan Değerleri**:
  - `DEFAULT_ETCD_IP`: ETCD'nin IP adresi. Varsayılan olarak `DEFAULT_SQL_VIRTUAL_IP` değerini kullanır.
  - `DEFAULT_ETCD_CLIENT_PORT`: ETCD istemci portu. Varsayılan değer: `"2379"`
  - `DEFAULT_ETCD_PEER_PORT`: ETCD peer portu. Varsayılan değer: `"2380"`
  - `DEFAULT_CLUSTER_TOKEN`: ETCD cluster token değeri. Varsayılan değer: `"cluster1"`
  - `DEFAULT_CLUSTER_STATE`: ETCD cluster durumu. Varsayılan değer: `"new"`
  - `DEFAULT_ETCD_NAME`: ETCD node adı. Varsayılan değer: `"etcd1"`
  - `DEFAULT_ELECTION_TIMEOUT`: ETCD seçim zaman aşımı değeri (ms). Varsayılan değer: `"5000"`
  - `DEFAULT_HEARTBEAT_INTERVAL`: ETCD kalp atışı aralığı (ms). Varsayılan değer: `"1000"`
  - `DEFAULT_DATA_DIR`: ETCD veri dizini yolu. Varsayılan değer: `"/var/lib/etcd/default"`

- **Docker Değişkenleri**:
  - `SHELL_PATH_IN_DOCKER`: Docker container içinde shell komutlarının bulunduğu dizin. Varsayılan değer: `"/usr/local/bin"`

### Kullanım

Bu değişkenler, diğer scriptlerde varsayılan değerleri atamak için kullanılır. Eğer kullanıcı tarafından bir değer belirtilmemişse, ilgili değişken bu dosyadaki varsayılan değeri alır. Böylece, sistem yapılandırması daha tutarlı ve yönetilebilir hale gelir.

### Notlar

- Değişken isimleri büyük harflerle ve `DEFAULT_` önekiyle tanımlanmıştır.
- `DEFAULT_ETCD_IP` değişkeni, `DEFAULT_SQL_VIRTUAL_IP` değerini kullanarak ETCD IP adresini otomatik olarak ayarlar.
- Bu dosya, sistem yöneticilerinin varsayılan ayarları merkezi bir yerden kontrol etmelerini sağlar.
- İhtiyaç duyulması halinde, bu varsayılan değerler güncellenebilir veya genişletilebilir.

</details>

<details>

<summary><strong>keepalived_scripts.sh</strong></summary>

Bu script koleksiyonu, **Keepalived** servisini kurmak, yapılandırmak ve yönetmek için gerekli fonksiyonları ve yardımcı scriptleri içerir. Keepalived, yüksek erişilebilirlik ve yük devretme (failover) sağlayarak servislerin kesintisiz çalışmasını hedefler.

### İçerikler

1. **create_keepalived.sh**

   - **Amaç**: Keepalived servisinin kurulumu ve yapılandırılması için ana script.
   - **İşlevleri**:
     - Gerekli diğer script dosyalarını dahil eder.
     - Kullanıcı argümanlarını kontrol eder ve parse eder.
     - Keepalived için gerekli kullanıcı ve izin yapılandırmalarını yapar.
     - Keepalived servisini kurar, yapılandırır ve başlatır.
     - İşlem tamamlandığında kullanıcıya bilgi verir.

2. **container_scripts.sh**

   - **Amaç**: Keepalived'in kontrol scriptlerini oluşturur.
   - **İşlevleri**:
     - `create_checkscript` fonksiyonu ile, belirtilen Docker konteynerinin çalışıp çalışmadığını kontrol eden bir script oluşturur.
     - Bu script, konteynerin durumu hakkında log bilgilerini `/var/log/keepalived_check.log` dosyasına yazar.

3. **keepalived_setup.sh**

   - **Amaç**: Keepalived servisinin kurulumu ve yapılandırılmasını yapar.
   - **İşlevleri**:
     - `install_keepalived`: Keepalived paketinin sistemde kurulu olup olmadığını kontrol eder, değilse kurar.
     - `configure_keepalived`: Keepalived için gerekli yapılandırma dosyalarını oluşturur ve VRRP instance'larını tanımlar.
       - SQL ve DNS için ayrı VRRP instance'ları yapılandırır.
       - Her bir instance için kontrol scriptlerini ve diğer ayarları belirler.
     - `start_keepalived`: Keepalived servisini başlatır ve sistem başlangıcında otomatik olarak başlaması için etkinleştirir.

4. **logging.sh**

   - **Amaç**: Keepalived kontrol scriptlerinin loglama işlevlerini yönetir.
   - **İşlevleri**:
     - `get_log_path`: Belirtilen konteyner için log dosyasının yolunu döndürür.
     - `setup_container_log`: Log dosyasının varlığını ve doğru izinlere sahip olup olmadığını kontrol eder; yoksa oluşturur ve izinleri ayarlar.

5. **user_management.sh**

   - **Amaç**: Keepalived'in çalışması için gerekli kullanıcı ve izin yapılandırmalarını yapar.
   - **İşlevleri**:
     - `create_keepalived_user`: `keepalived_script` adlı sistem kullanıcısını oluşturur.
     - `check_and_add_docker_permissions`: `keepalived_script` kullanıcısının `docker` grubuna üye olup olmadığını kontrol eder; değilse ekler.
     - `configure_sudo_access`: `keepalived_script` kullanıcısına `sudo` üzerinden `docker` komutlarını şifresiz çalıştırabilme izni verir.

### Genel Akış

- **create_keepalived.sh** scripti çalıştırıldığında:
  - Gerekli argümanlar kontrol edilir ve parse edilir.
  - Gerekli kullanıcı ve grup izinleri ayarlanır.
  - Keepalived servisi kurulur ve yapılandırılır.
  - Kontrol scriptleri ve loglama mekanizmaları oluşturulur.
  - Keepalived servisi başlatılır ve etkinleştirilir.

### Notlar

- **Güvenlik**:
  - `keepalived_script` kullanıcısına sadece gerekli izinler verilir.
  - Sudo konfigurasyonu ile `docker` komutlarının şifresiz çalıştırılması sağlanır; bu nedenle sudoers dosyası dikkatli bir şekilde yapılandırılır.

- **Loglama**:
  - Kontrol scriptleri, konteynerlerin durumu hakkında log bilgilerini `/var/log/{CONTAINER_NAME}_check.log` dosyasına yazar.
  - Log dosyalarının doğru sahiplik ve izinlere sahip olması sağlanır.

- **Yapılandırma Dosyaları**:
  - `/etc/keepalived/keepalived.conf` dosyası, VRRP instance'larını ve kontrol scriptlerini tanımlar.
  - SQL ve DNS hizmetleri için ayrı VRRP instance'ları ve kontrol scriptleri yapılandırılır.

- **Servis Yönetimi**:
  - Keepalived servisi, sistem yeniden başlatıldığında otomatik olarak başlayacak şekilde etkinleştirilir.
  - Servisin durumu kontrol edilir ve gerekirse yeniden başlatılır.

### Kullanım

- **Script'i Çalıştırma**:

  ```bash
  ./create_keepalived.sh [ARGÜMANLAR]
    ```
</details>

# keepalived
Keepalived, yüksek erişilebilirlik sağlamak için kullanılan bir yazılımdır. Keepalived, birincil ve yedek sunucular arasında bir sanal IP adresi üzerinden otomatik olarak geçiş yapar. Keepalived, birincil sunucunun çalışıp çalışmadığını kontrol eder ve birincil sunucu çalışmıyorsa yedek sunucuyu birincil sunucu olarak devreye alır.

## keepalived kurulumu
```bash
cd keepalived_scripts
bash create_keepalived.sh
```

# bind9
Bind9, DNS sunucusu yazılımıdır. Bu yazılım, DNS sorgularını alır ve DNS kayıtlarını çözümleyerek istemcilere cevaplar. Bu yazılım, DNS sunucularının yüksek erişilebilirlik sağlamasını sağlar.

## bind9 kurulumu
```bash
cd docker_scripts
bash docker_dns.sh
```

# postgresql
PostgreSQL, ilişkisel veritabanı yönetim sistemidir. Bu yazılım, veritabanı sorgularını alır ve veritabanı işlemlerini gerçekleştirir. Bu yazılım, veritabanı sunucularının yüksek erişilebilirlik sağlamasını sağlar. Yüksek erişilebilirlik sağlamak için patroni, etcd ve haproxy yazılımlarıyla beraber kullanılması gerekmektedir.

## postgresql kurulumu
```bash
cd docker_scripts
bash docker_sql.sh
```