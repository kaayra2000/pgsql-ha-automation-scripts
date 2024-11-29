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
ETCD_ELECTION_TIMEOUT=5000
NODE2_IP=10.207.80.11
REPLIKATOR_KULLANICI_ADI=replicator
KEEPALIVED_PRIORITY=100
KEEPALIVED_INTERFACE=et123456
IS_NODE_1=true
HAPROXY_BIND_PORT=7000
DNS_CONTAINER_NAME=dns_1
ETCD_NAME=etcd1
POSTGRES_SIFRESI=postgres_pass
ETCD_CLIENT_PORT=2379
ETCD_HEARTBEAT_INTERVAL=1000
ETCD_IP=10.207.80.20
PATRONI_NODE_NAME=pg_node1
PGSQL_PORT=5432
ETCD_CLUSTER_KEEPALIVED_STATE=new
ETCD_DATA_DIR=/var/lib/etcd/default
ETCD_CLUSTER_TOKEN=cluster1
ETCD_PEER_PORT=2380
PGSQL_BIND_PORT=5000
HAPROXY_PORT=8008
REPLICATOR_SIFRESI=replicator_pass
SQL_CONTAINER_NAME=sql_1
NODE1_IP=10.207.80.10
KEEPALIVED_STATE=BACKUP
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
  * parse_and_read_arguments fonksiyonu, argümanları dosyaya yazdığı için scriptin başında çağrılmalıdır.
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
  - `DEFAULT_PATRONI_NODE_NAME`: Node adı. Varsayılan değer: `"pg_node1"`
  - `DEFAULT_PGSQL_PORT`: PostgreSQL'in dinlediği port. Varsayılan değer: `"5432"`
  - `DEFAULT_PGSQL_BIND_PORT`: PostgreSQL'in bağlanacağı port. Varsayılan değer: `"5000"`
  - `DEFAULT_REPLIKATOR_KULLANICI_ADI`: Replikasyon için kullanılacak kullanıcı adı. Varsayılan değer: `"replicator"`
  - `DEFAULT_REPLICATOR_SIFRESI`: Replikasyon kullanıcısının şifresi. Varsayılan değer: `"replicator_pass"`
  - `DEFAULT_POSTGRES_SIFRESI`: PostgreSQL veritabanı kullanıcısının şifresi. Varsayılan değer: `"postgres_pass"`
  - `DEFAULT_IS_NODE_1`: Node'un birinci node olup olmadığını belirten değer. Varsayılan değer: `"true"`

- **Keepalived Değişkenleri**:
  - `DEFAULT_KEEPALIVED_INTERFACE`: Ağ arayüzü adı. Varsayılan değer: `"enp0s3"`
  - `DEFAULT_SQL_VIRTUAL_IP`: SQL için sanal IP adresi. Varsayılan değer: `"10.207.80.20"`
  - `DEFAULT_DNS_VIRTUAL_IP`: DNS için sanal IP adresi. Varsayılan değer: `"10.207.80.30"`
  - `DEFAULT_KEEPALIVED_PRIORITY`: Keepalived öncelik değeri. Varsayılan değer: `"100"`
  - `DEFAULT_KEEPALIVED_STATE`: Keepalived durumunu belirtir (`MASTER` veya `BACKUP`). Varsayılan değer: `"BACKUP"`
  - `DEFAULT_SQL_CONTAINER_NAME`: SQL için Docker container adı. Varsayılan değer: `"sql_container"`
  - `DEFAULT_DNS_CONTAINER_NAME`: DNS için Docker container adı. Varsayılan değer: `"dns_container"`

- **ETCD Varsayılan Değerleri**:
  - `DEFAULT_ETCD_IP`: ETCD'nin IP adresi. Varsayılan olarak `DEFAULT_SQL_VIRTUAL_IP` değerini kullanır.
  - `DEFAULT_ETCD_CLIENT_PORT`: ETCD istemci portu. Varsayılan değer: `"2379"`
  - `DEFAULT_ETCD_PEER_PORT`: ETCD peer portu. Varsayılan değer: `"2380"`
  - `DEFAULT_ETCD_CLUSTER_TOKEN`: ETCD cluster token değeri. Varsayılan değer: `"cluster1"`
  - `DEFAULT_ETCD_CLUSTER_KEEPALIVED_STATE`: ETCD cluster durumu. Varsayılan değer: `"new"`
  - `DEFAULT_ETCD_NAME`: ETCD node adı. Varsayılan değer: `"etcd1"`
  - `DEFAULT_ETCD_ELECTION_TIMEOUT`: ETCD seçim zaman aşımı değeri (ms). Varsayılan değer: `"5000"`
  - `DEFAULT_ETCD_HEARTBEAT_INTERVAL`: ETCD kalp atışı aralığı (ms). Varsayılan değer: `"1000"`
  - `DEFAULT_ETCD_DATA_DIR`: ETCD veri dizini yolu. Varsayılan değer: `"/var/lib/etcd/default"`

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

<summary><strong>keepalived_scripts</strong></summary>

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

<details>

<summary><strong>haproxy_scripts</strong></summary>

Bu script seti, **HAProxy** servisinin kurulumu, yapılandırılması ve başlatılması için gerekli fonksiyonları ve yardımcı scriptleri içerir. HAProxy, yüksek performanslı bir TCP/HTTP yük dengeleyici ve proxy sunucusudur ve bu scriptler aracılığıyla PostgreSQL hizmetlerinin yük dengelemesini sağlar.

### İçerikler

1. **create_haproxy.sh**

   - **Amaç**: HAProxy servisinin kurulumu ve yapılandırılması için ana script.
   - **İşlevleri**:
     - Gerekli script dosyalarını dahil eder:
       - `haproxy_setup.sh`: HAProxy kurulumu ve yapılandırma fonksiyonlarını içerir.
       - `argument_parser.sh`: Kullanıcı argümanlarını parse etmek için kullanılır.
       - `general_functions.sh`: Genel amaçlı yardımcı fonksiyonları içerir.
     - `parse_and_read_arguments` fonksiyonunu çağırarak kullanıcının verdiği argümanları kontrol eder ve parse eder.
     - Aşağıdaki fonksiyonları sırasıyla çağırır:
       - `ha_proxy_kur`: HAProxy paketini kurar.
       - `ha_proxy_konfigure_et`: HAProxy yapılandırma dosyasını oluşturur.
       - `enable_haproxy`: HAProxy servisinin konfigürasyonunu kontrol eder ve servisi başlatır.

2. **haproxy_setup.sh**

   - **Amaç**: HAProxy servisinin kurulumu, yapılandırılması ve başlatılması için gerekli fonksiyonları içerir.
   - **İşlevleri**:
     - **ha_proxy_kur**:
       - HAProxy paketini sistem üzerine kurar.
       - Kurulum sırasında oluşabilecek hataları kontrol eder ve kullanıcıya bildirir.
     - **ha_proxy_konfigure_et**:
       - HAProxy için `/etc/haproxy/haproxy.cfg` yapılandırma dosyasını oluşturur.
       - Yapılandırma dosyasında şunları tanımlar:
         - **global** ve **defaults** ayarları: Maksimum bağlantı sayısı, log ayarları, timeout değerleri vb.
         - **frontend stats** ve **backend stats_backend**: HAProxy istatistik arayüzü için frontend ve backend tanımları.
           - İstatistik arayüzü belirlenen `$HAPROXY_BIND_PORT` portunda çalışır.
         - **frontend postgres_frontend** ve **backend postgres_backend**:
           - PostgreSQL hizmeti için frontend ve backend tanımları.
           - `$PGSQL_BIND_PORT` portunda gelen bağlantıları kabul eder ve backend sunucularına yönlendirir.
           - Backend sunucuları olarak `node-1` ve `node-2` tanımlanır, bu sunucular `$NODE1_IP` ve `$NODE2_IP` adreslerinde bulunan PostgreSQL hizmetleridir.
           - Yük dengeleme algoritması olarak `roundrobin` kullanılır.
           - Sunucu sağlık kontrolü için `tcp-check` yapılır.
     - **enable_haproxy**:
       - HAProxy konfigürasyon dosyasının doğruluğunu kontrol eder.
       - Konfigürasyon geçerliyse HAProxy servisini başlatır.
       - Servisin başlatılması sırasında oluşabilecek hataları kontrol eder ve kullanıcıya bildirir.

### Genel Akış

- **create_haproxy.sh** scripti çalıştırıldığında:
  - Gerekli argümanları kontrol eder ve parse eder.
  - HAProxy kurulumunu gerçekleştirir (`ha_proxy_kur`).
  - HAProxy yapılandırma dosyasını oluşturur (`ha_proxy_konfigure_et`).
  - HAProxy servisini başlatır ve yapılandırmayı etkinleştirir (`enable_haproxy`).

### Notlar

- **Bağımlılıklar**:
  - Scriptler, diğer yardımcı script dosyalarına bağımlıdır:
    - `argument_parser.sh`: Kullanıcıdan gelen argümanları işler.
    - `general_functions.sh`: Genel yardımcı fonksiyonları sağlar (örneğin, `check_success` fonksiyonu).
- **Değişkenler**:
  - `$HAPROXY_BIND_PORT`: HAProxy'nin istatistik arayüzü için bind edildiği port.
  - `$PGSQL_BIND_PORT`: HAProxy'nin PostgreSQL frontend'inin dinlediği port.
  - `$NODE1_IP` ve `$NODE2_IP`: Backend PostgreSQL sunucularının IP adresleri.
  - `$PGSQL_PORT`: Backend PostgreSQL sunucularının dinlediği port.
- **Yapılandırma Dosyası**:
  - `/etc/haproxy/haproxy.cfg`: HAProxy'nin ana yapılandırma dosyasıdır ve script tarafından otomatik olarak oluşturulur.
- **Servis Yönetimi**:
  - HAProxy servisinin başlatılması ve konfigürasyonunun kontrolü otomatik olarak yapılır.
  - Konfigürasyon dosyasında hata olması durumunda servis başlatılmaz ve kullanıcıya hata mesajı gösterilir.
  
### Kullanım

- **Script'i Çalıştırma**:

  ```bash
  ./create_haproxy.sh [ARGÜMANLAR]
    ```
</details>    

<details>

<summary><strong>etcd_scripts</strong></summary>

Bu script seti, **etcd** servisinin kurulumu, yapılandırılması ve başlatılması için gerekli fonksiyonları ve yardımcı scriptleri içerir. etcd, dağıtık sistemlerde yüksek erişilebilirlik ve tutarlılık sağlayan bir anahtar-değer depolama sistemidir ve bu scriptler aracılığıyla etcd servisini kolayca yönetebilirsiniz.

### İçerikler

1. **create_etcd.sh**

   - **Amaç**: etcd servisinin kurulumu ve yapılandırılması için ana script.
   - **İşlevleri**:
     - Gerekli diğer script dosyalarını dahil eder:
       - `etcd_setup.sh`: etcd'nin kurulumu ve yapılandırılması için fonksiyonları içerir.
       - `argument_parser.sh`: Kullanıcı argümanlarını parse etmek için kullanılır.
       - `general_functions.sh`: Genel amaçlı yardımcı fonksiyonları içerir.
     - `parse_and_read_arguments` fonksiyonunu çağırarak kullanıcının verdiği argümanları kontrol eder ve parse eder.
     - Kullanıcı tarafından belirtilen veya varsayılan değerlerin kullanıldığı değişkenleri kontrol eder ve gerekli dizinlerin mevcut olup olmadığını kontrol eder; yoksa oluşturur.
     - `check_user_exists` fonksiyonu ile etcd için gerekli kullanıcının sistemde mevcut olup olmadığını kontrol eder.
     - Dizinlerin ve konfigürasyon dosyalarının sahipliğini ve izinlerini ayarlar:
       - `set_permissions` fonksiyonu ile `$ETCD_DATA_DIR` ve `$ETCD_CONFIG_DIR` dizinlerinin sahipliğini ve izinlerini etcd kullanıcısına göre ayarlar.
     - etcd kurulumu ve yapılandırmasını gerçekleştirir:
       - `etcd_kur` fonksiyonu ile etcd paketini kurar.
       - `etcd_konfigure_et` fonksiyonu ile etcd konfigürasyon dosyasını oluşturur.
       - Konfigürasyon dosyasının sahipliğini ve izinlerini ayarlar.
       - `update_daemon_args` fonksiyonu ile etcd servisinin başlangıç argümanlarını günceller, böylece servis belirtilen konfigürasyon dosyasını kullanır.
     - etcd servisini başlatır ve durumunu kontrol eder:
       - `etcd_etkinlestir` fonksiyonu ile etcd servisini başlatır ve API'nin çalışıp çalışmadığını kontrol eder.
     - İşlem sırasında oluşabilecek hataları kontrol eder ve kullanıcıya bilgilendirir.

2. **etcd_setup.sh**

   - **Amaç**: etcd servisinin kurulumu, yapılandırılması ve başlatılması için gerekli fonksiyonları içerir.
   - **İşlevleri**:
     - **etcd_kur**:
       - etcd paketini sistem üzerine kurar.
       - Kurulum sırasında oluşabilecek hataları kontrol eder ve kullanıcıya bildirir.
     - **etcd_konfigure_et**:
       - etcd için YAML formatında konfigürasyon dosyasını oluşturur.
       - Konfigürasyon dosyasında şunları tanımlar:
         - Sunucu adı (`name`), veri dizini (`data-dir`), dinlenecek adresler ve portlar (`listen-peer-urls`, `listen-client-urls`), duyurulacak adresler (`initial-advertise-peer-urls`, `advertise-client-urls`), cluster bilgileri (`initial-cluster`, `initial-cluster-token`, `initial-cluster-state`), zaman aşımı değerleri (`election-timeout`, `heartbeat-interval`) ve diğer ayarlar.
       - Oluşturulan konfigürasyon dosyasında oluşabilecek hataları kontrol eder.
     - **update_daemon_args**:
       - etcd servisini başlatırken kullanılacak argümanları günceller.
       - `/etc/init.d/etcd` dosyasındaki `DAEMON_ARGS` satırını, oluşturulan konfigürasyon dosyasını kullanacak şekilde günceller veya ekler.
     - **etcd_etkinlestir**:
       - etcd servisini durdurur ve yeniden başlatır.
       - Servisin durumu ve API'nin çalışıp çalışmadığını kontrol eder.
       - Servis başlatılamazsa veya API yanıt vermiyorsa kullanıcıya hata mesajı gösterir.

### Genel Akış

- **create_etcd.sh** scripti çalıştırıldığında:
  - Gerekli argümanları kontrol eder ve parse eder.
  - Gerekli dizinleri kontrol eder ve oluşturur.
  - etcd kullanıcısının mevcut olduğunu kontrol eder ve gerekli izinleri ayarlar.
  - etcd kurulumunu gerçekleştirir (`etcd_kur`).
  - etcd yapılandırma dosyasını oluşturur (`etcd_konfigure_et`).
  - etcd servisinin başlangıç argümanlarını günceller (`update_daemon_args`).
  - etcd servisini başlatır ve API'nin durumunu kontrol eder (`etcd_etkinlestir`).

### Notlar

- **Bağımlılıklar**:
  - Scriptler, diğer yardımcı script dosyalarına bağımlıdır:
    - `argument_parser.sh`: Kullanıcıdan gelen argümanları işler.
    - `general_functions.sh`: Genel yardımcı fonksiyonları sağlar (örneğin, `check_success`, `check_user_exists`, `set_permissions` gibi).
- **Değişkenler**:
  - `$ETCD_CONFIG_DIR`: etcd konfigürasyon dosyalarının bulunduğu dizin (`/etc/etcd`).
  - `$ETCD_CONFIG_FILE`: etcd ana konfigürasyon dosyasının tam yolu.
  - `$ETCD_DATA_DIR`: etcd'nin veri depolama dizini.
  - `$ETCD_USER`: etcd servisini çalıştıracak kullanıcı adı (`etcd`).
  - `$ETCD_IP`, `$ETCD_CLIENT_PORT`, `$ETCD_PEER_PORT`: etcd'nin dinleyeceği IP adresi ve portlar.
  - `$ETCD_NAME`: etcd node adı.
  - `$ETCD_CLUSTER_TOKEN`, `$ETCD_CLUSTER_KEEPALIVED_STATE`: etcd cluster bilgileri.
  - `$ETCD_ELECTION_TIMEOUT`, `$ETCD_HEARTBEAT_INTERVAL`: etcd zaman aşımı ayarları.
- **Yapılandırma Dosyası**:
  - etcd için oluşturulan `etcd.conf.yml` dosyası, etcd servisinin çalışma parametrelerini belirler.
- **Servis Yönetimi**:
  - etcd servisi, sistem servis yöneticisi aracılığıyla (`service etcd start/stop/status`) kontrol edilir.
  - Servisin başarıyla başlatılıp başlatılmadığı ve API'nin çalışıp çalışmadığı kontrol edilir.

### Kullanım

- **Script'i Çalıştırma**:

  ```bash
  ./create_etcd.sh [ARGÜMANLAR]
    ```
- **Örnek Argümanlar:**
    - --etcd-ip: etcd sunucusunun dinleyeceği IP adresi.
    - --etcd-name: etcd node adı.
    - --data-dir: etcd veri dizini.
    - --etcd-client-port: etcd istemci portu.
    - --etcd-peer-port: etcd peer portu.
    - Diğer gerekli argümanlar argument_parser.sh tarafından yönetilir.

- **Gereksinimler:**
    * Scriptlerin başarılı bir şekilde çalışması için gerekli paketlerin ve izinlerin sağlanması gerekir.
    * etcd kullanıcısının sistemde mevcut olması gerekir; yoksa oluşturulmalıdır.
    * Scriptler Ubuntu/Debian tabanlı sistemler için tasarlanmıştır.

</details>

<details>

<summary><strong>docker_scripts</strong></summary>

Bu script seti, Docker imajları ve konteynerleri oluşturmak, yapılandırmak ve çalıştırmak için gerekli fonksiyonları ve yardımcı scriptleri içerir. Bu scriptler aracılığıyla, DNS ve SQL hizmetleri için özel Docker konteynerleri oluşturabilir ve yönetebilirsiniz.

### İçerikler

1. **docker_dns.sh**

   - **Amaç**: DNS hizmeti için Docker imajı oluşturur ve konteyneri çalıştırır.
   - **İşlevleri**:
     - Gerekli scriptleri ve değişkenleri dahil eder:
       - `create_image.sh`: Docker imajı oluşturmak için fonksiyonları içerir.
       - `argument_parser.sh`: Kullanıcı argümanlarını parse etmek için kullanılır.
       - `default_variables.sh`, `general_functions.sh`: Genel amaçlı değişkenleri ve fonksiyonları içerir.
     - Varsayılan değerleri ve sabitleri tanımlar:
       - `DNS_PORT`, `HOST_PORT`: DNS hizmeti için konteyner içi ve host port numaraları.
       - `DOCKERFILE_PATH`, `DOCKERFILE_NAME`: Dockerfile'ın yolu ve adı.
       - `DNS_CONTAINER_NAME`, `IMAGE_NAME`: Docker konteyneri ve imajı için isimler.
       - `SHELL_SCRIPT_NAME`: Konteyner içinde çalıştırılacak scriptin adı (`create_dns_server.sh`).
     - `dns_parser` fonksiyonu ile kullanıcıdan gelen argümanları işler.
     - `create_image` fonksiyonunu çağırarak DNS hizmeti için Docker imajını oluşturur.
     - `run_container` fonksiyonu ile Docker konteynerini çalıştırır.
       - Konteyner çalıştırılırken gerekli port yönlendirmelerini ve yetkileri ayarlar.
       - Konteyner içinde DNS sunucusunu ve Keepalived'i başlatır.
   
2. **docker_sql.sh**

   - **Amaç**: SQL (PostgreSQL) ve HAProxy hizmetleri için Docker imajı oluşturur ve konteyneri çalıştırır.
   - **İşlevleri**:
     - Gerekli scriptleri ve değişkenleri dahil eder:
       - `create_image.sh`: Docker imajı oluşturmak için fonksiyonları içerir.
       - `argument_parser.sh`: Kullanıcı argümanlarını parse etmek için kullanılır.
       - `default_variables.sh`, `general_functions.sh`: Genel amaçlı değişkenleri ve fonksiyonları içerir.
     - Varsayılan değerleri ve sabitleri tanırlar:
       - `HAPROXY_PORT`, `HOST_PORT`: HAProxy için konteyner içi ve host port numaraları.
       - `DOCKERFILE_PATH`, `DOCKERFILE_NAME`: Dockerfile'ın yolu ve adı.
       - `SQL_CONTAINER_NAME`, `IMAGE_NAME`: Docker konteyneri ve imajı için isimler.
       - `HAPROXY_SCRIPT_FOLDER`, `HAPROXY_SCRIPT_NAME`: Konteyner içinde çalıştırılacak HAProxy scriptinin yolu ve adı.
       - `ETCD_SCRIPT_FOLDER`, `ETCD_SCRIPT_NAME`: Konteyner içinde çalıştırılacak etcd scriptinin yolu ve adı.
     - `parse_all_arguments` fonksiyonu ile kullanıcıdan gelen argümanları işler.
     - `create_image` fonksiyonunu çağırarak SQL ve HAProxy hizmetleri için Docker imajını oluşturur.
     - `run_container` fonksiyonu ile Docker konteynerini çalıştırır.
       - Konteyner çalıştırılırken gerekli port yönlendirmelerini ve yetkileri ayarlar.
       - Konteyner içinde etcd ve HAProxy servislerini başlatır.

3. **create_image.sh**

   - **Amaç**: Belirtilen Dockerfile ve bağlam (context) kullanılarak Docker imajı oluşturur.
   - **İşlevleri**:
     - `create_image` fonksiyonu ile Docker imajının mevcut olup olmadığını kontrol eder.
     - İmaj mevcutsa, kullanıcıya yeniden oluşturmak isteyip istemediğini sorar.
     - Docker imajını oluşturur veya yeniden oluşturur.
     - Oluşturma işlemi sırasında oluşabilecek hataları kontrol eder ve kullanıcıya bildirir.

4. **argument_parser.sh**

   - **Amaç**: Docker scriptleri için kullanıcıdan gelen argümanları parse eder ve doğrular.
   - **İşlevleri**:
     - `dns_parser` ve `sql_parser` fonksiyonları ile ilgili argümanları işler.
       - Argümanları varsayılan değerlerle birleştirir.
       - Argümanların geçerliliğini kontrol eder (örneğin, port numaralarının doğruluğu).
     - `process_argument` ve `parse_arguments` yardımcı fonksiyonları ile genel argüman işleme işlemlerini gerçekleştirir.
     - Yardım mesajlarını gösterir ve kullanıcının doğru şekilde yönlendirilmesini sağlar.

### Genel Akış

- **DNS Hizmeti için**:
  - `docker_dns.sh` scripti çalıştırılır.
  - Kullanıcıdan gelen argümanlar parse edilir.
  - Docker imajı oluşturulur (`dns_image`).
  - Docker konteyneri başlatılır (`dns_container`), gerekli servisler çalıştırılır.

- **SQL ve HAProxy Hizmeti için**:
  - `docker_sql.sh` scripti çalıştırılır.
  - Kullanıcıdan gelen argümanlar parse edilir.
  - Docker imajı oluşturulur (`sql_image`).
  - Docker konteyneri başlatılır (`sql_container`), etcd ve HAProxy servisleri çalıştırılır.

### Notlar

- **Bağımlılıklar**:
  - Bu scriptler, diğer yardımcı script dosyalarına ve Dockerfile'lara bağımlıdır.
  - `create_image.sh` genel amaçlı Docker imajı oluşturma fonksiyonlarını içerir ve diğer scriptler tarafından kullanılır.
  - `argument_parser.sh` kullanıcı argümanlarını işlemek için kullanılır ve scriptlerin esnekliğini artırır.

- **Değişkenler ve Sabitler**:
  - Scriptler içinde kullanılan port numaraları, konteyner ve imaj isimleri gibi değerler tanımlanmıştır ve gerektiğinde kullanıcı argümanları ile değiştirilebilir.

- **Güvenlik ve Yetkiler**:
  - Docker konteynerleri çalıştırılırken `--privileged` ve `--cap-add=NET_ADMIN` gibi seçenekler kullanılır.
  - Bu nedenle, scriptleri çalıştırırken dikkatli olunmalı ve gerekli izinlere sahip olunduğundan emin olunmalıdır.

- **Konteyner İçindeki İşlemler**:
  - Konteynerler başlatıldığında, ilgili servisleri çalıştırmak için belirli scriptler çağrılır.
  - Örneğin, `docker_dns.sh` içinde `create_dns_server.sh` scripti konteyner içinde çalıştırılır ve DNS sunucusu kurulur.

- **Loglama ve Hata Yönetimi**:
  - `check_success` fonksiyonu ile her adımın başarılı olup olmadığı kontrol edilir.
  - Oluşabilecek hatalar kullanıcıya bildirilir ve gerekli önlemler alınabilir.

### Kullanım

- **DNS Hizmeti için**:

  ```bash
  ./docker_dns.sh [--host-port <HOST_PORT>] [--dns-port <DNS_PORT>]
    ```

- **SQL ve HAProxy Hizmeti için**:
    
    ```bash
    ./docker_sql.sh [--host-port <HOST_PORT>] [--haproxy-port <HAPROXY_PORT>]
    ```
    - --host-port: Host üzerinde yönlendirilecek port (varsayılan: 8404).
    - --haproxy-port: HAProxy hizmetinin dinleyeceği port (varsayılan: 8404).
- **Örnek**:
    ```bash
    ./docker_dns.sh --host-port 1053 --dns-port 53
    ./docker_sql.sh --host-port 8500 --haproxy-port 8404
    ```

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
./create_dns_server.sh --dns-port 53 --dns-docker-forward-port 53 
```

## Not

- Eğer argümanları teker teker geçirmek istemiyorsanız `arguments.cfg` dosyasını düzenleyerek `create_dns_server.sh` dosyasını çalıştırabilirsiniz. Zaten varsayılan olarak oradaki değerler alınacaktır.

- Eğer argümanları yukarıdaki örnekteki gibi geçirirseniz `create_dns_server.sh` dosyası `arguments.cfg` dosyasındaki değerleri değiştirecektir. Bu durumda, ilk geçirdiğiniz değerleri tekrar geçirmek istiyorsanız, bir daha argümanaları yukarıdaki örnekteki gibi geçirmenize gerek yoktur.

- `arguments.cfg` dosyasında bu `create_dns_server.sh` dosyasında kullanılmayan argümanlar da bulunmaktadır. Tüm ***komut*** (.sh) dosyalarının argümanları tek bir merkezde toplandığı için bu durum normaldir. Eğer sadece `create_dns_server.sh` komut dosyasını çalıştıracaksanız `arguments.cfg` dosyasındaki fazlalık argümanları umursamayın.