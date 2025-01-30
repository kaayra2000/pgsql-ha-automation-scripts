# RabbitMQ Yedeklilik (Cluster) Yapısı

Bu doküman, RabbitMQ kullanarak yedeklilik (cluster) yapısını adım adım nasıl hayata geçirebileceğinizi anlatır. Ayrıca ağ partition senaryoları, node ekleme/çıkarma, kritik durumlar (uç senaryolar) ve node yönetimiyle ilgili önemli noktaları da içermektedir. Buradaki bilgiler, resmi RabbitMQ Clustering dokümantasyonuna dayanmaktadır.

## 1. Giriş ve Temel Kavramlar

### RabbitMQ Cluster Nedir?

#### Genel Bakış
RabbitMQ cluster, bir veya birden fazla node'un (genellikle 3, 5, 7 gibi tek sayıda) mantıksal olarak bir arada çalıştığı yapıdır.

#### Paylaşılan Kaynaklar
Cluster yapısında aşağıdaki kaynaklar tüm node'lar arasında paylaşılır:
- Kullanıcılar
- Sanal host'lar 
- Kuyruklar
- Exchange'ler
- Binding'ler
- Diğer dağıtık veriler

#### Mesaj Depolama
- **Classic Queue**: Varsayılan olarak mesajlar tek bir node'daki kuyrukta tutulur
- **Quorum Queue / Stream**: Mesajlar birden fazla node'a replike edilerek yazılır

#### Önemli Noktalar
1. **Node Sayısı**
   - Genellikle tek sayıda node kullanılır (3,5,7...)
   - Bu sayede consensus (fikir birliği) daha kolay sağlanır

2. **Yüksek Erişilebilirlik**
   - Node'lardan biri düşse bile sistem çalışmaya devam eder
   - Quorum Queue ile mesaj kaybı riski minimize edilir

3. **Ölçeklenebilirlik**
   - İhtiyaca göre node sayısı artırılabilir
   - Yük birden fazla node'a dağıtılabilir

4. **Yönetim**
   - Tüm cluster tek bir birim gibi yönetilebilir
   - Node'lar dinamik olarak eklenip çıkarılabilir

### RabbitMQ Node İsimleri

#### Genel Bakış
RabbitMQ node'ları benzersiz bir node ismi ile tanımlanır ve bu isim cluster iletişiminde kritik bir rol oynar.

#### Node İsim Formatı
- Format: `rabbit@hostname` 
- Örnek: `rabbit@node1.messaging.svc.local`

#### Temel Özellikler

###### 1. Benzersizlik
- Her node ismi cluster içinde benzersiz olmalıdır
- İki node aynı ismi paylaşamaz

###### 2. İletişim Gereksinimleri
- Node'lar birbirleriyle bu isimler üzerinden iletişim kurar
- Node'lar birbirlerinin hostname'lerini çözümleyebilmelidir
- Hostname çözümleme yöntemleri:
  - DNS kayıtları
  - Yerel host dosyaları (/etc/hosts)
  - Özel hostname çözümleme mekanizmaları

###### 3. Hostname Çözümleme
- Tüm node'lar birbirlerinin hostname'lerini çözebilmelidir
- Hostname çözümlemesi olmadan cluster çalışmaz
- Hostname değişiklikleri node'un yeniden başlatılmasını gerektirir

###### 4. Güvenlik
- Node isimleri hassas bilgilerdir
- Hostname çözümlemesi güvenli bir şekilde yapılmalıdır
- DNS veya hosts dosyası manipülasyonlarına karşı korunmalıdır

###### 5. En Verimli Uygulama
- Tutarlı bir isimlendirme standardı kullanın
- IP adresleri yerine DNS isimlerini tercih edin  
- Hostname değişikliklerinden kaçının
- Node isimlerini dokümante edin

### Erlang Cookie Nedir?

#### Genel Bakış
Erlang cookie, RabbitMQ node'ları ve CLI araçları arasındaki güvenli iletişimi sağlayan paylaşılan bir gizli anahtardır.

#### Cookie Gereksinimleri
- Tüm cluster node'ları aynı cookie değerini paylaşmalıdır
- CLI araçları (örn. rabbitmqctl) node'larla iletişim için aynı cookie'yi kullanmalıdır
- Cookie dosyası sadece sahibi tarafından erişilebilir olmalıdır (UNIX izinleri 600)

#### Cookie Dosya Konumları

##### Linux/macOS/BSD
- Server için: `/var/lib/rabbitmq/.erlang.cookie`
- CLI araçları için: `$HOME/.erlang.cookie`

##### Windows
- Service için: `C:\Windows\system32\config\systemprofile\.erlang.cookie`
- CLI araçları için: `%USERPROFILE%\.erlang.cookie`

#### Önemli Noktalar

1. **Güvenlik**
   - Cookie değeri cluster güvenliği için kritiktir
   - Dosya izinleri doğru ayarlanmalıdır
   - Cookie değeri güvenli şekilde saklanmalıdır

2. **Cluster Davranışı**
   - Cookie değerleri eşleşmezse node'lar birbirine bağlanamaz
   - CLI araçları cookie uyuşmazlığında çalışmaz

3. **Yapılandırma**
   - Cookie değeri manuel olarak ayarlanabilir
   - Tüm node'larda aynı değer kullanılmalıdır
   - Değişiklikler node'ların yeniden başlatılmasını gerektirir

4. **En Verimli Uygulama**
   - Cookie değerini deployment aşamasında ayarlayın
   - Otomasyon araçları ile yönetin
   - Cookie değerini güvenli şekilde yedekleyin

### Neden Tek Sayıda Node Kullanılmalı?

#### Genel Bakış
Yüksek erişilebilirlik gerektiren yapılarda (örneğin quorum kuyruklar) node sayısının tek olması önerilir (3, 5, 7 gibi).

#### Çift Sayıda Node'un Dezavantajları

1. **Çoğunluk Problemi**
   - İki node'lu cluster önerilmez
   - Ağ kopması durumunda çoğunluk sağlanamaz
   - Node hatalarında konsensüs oluşturulamaz

2. **Servis Kesintileri**
   - Çoğunluk sağlanamadığında:
     - Kuyruklar çalışmaz
     - Client bağlantıları başarısız olur
     - Sistem kullanılamaz hale gelir

#### Önerilen Node Sayıları

1. **Tek Node**
   - Test ve geliştirme ortamları için
   - Yüksek erişilebilirlik gerekmeyen durumlar

2. **Üç Node**
   - Minimum yüksek erişilebilirlik için
   - Bir node'un kaybı tolere edilebilir

3. **Beş Node**
   - Daha yüksek erişilebilirlik için
   - İki node'un kaybı tolere edilebilir

4. **Yedi Node**
   - Maksimum erişilebilirlik için
   - Üç node'un kaybı tolere edilebilir

#### En Verimli Uygulama

1. **Node Sayısı Seçimi**
   - İhtiyaca göre tek sayıda node seçin
   - Cluster büyüklüğünü iş yüküne göre belirleyin
   - Gereksiz node sayısından kaçının

2. **Yedeklilik Planlaması**
   - Node kayıplarını tolere edebilecek sayıda node kullanın
   - Bakım/güncelleme senaryolarını göz önünde bulundurun

## 2. Gerekli Bağımlılıklar ve Portlar

### 1. Hostname Çözümleme
- Tüm node'lar kendi hostname'lerini çözebilmelidir
- Tüm node'lar diğer node'ların hostname'lerini çözebilmelidir 
- CLI araçları (rabbitmqctl vb.) node'lara erişebilmelidir

### 2. Açık Olması Gereken Portlar

#### Temel Portlar
- **4369**: epmd (Erlang Port Mapper Daemon)
  - Node keşfi için kullanılır
  - Node'ların birbirini bulmasını sağlar

- **25672**: Erlang Dağıtımı
  - Node'lar arası dağıtık iletişim için kullanılır
  - CLI araçları bu portu kullanır
  - Varsayılan AMQP portu + 20000 ile hesaplanır

- **35672-35682**: CLI Araçları
  - CLI araçlarının node'larla iletişimi için kullanılır
  - Port aralığı olarak tanımlanmıştır

#### Opsiyonel Portlar
- **6000-6500**: RabbitMQ Stream Replikasyonu
  - Stream özelliği kullanılıyorsa gereklidir

### 3. Güvenlik Duvarı Gereksinimleri
- Tüm portlar iki yönlü açık olmalıdır
- İç ağda node'lar arası iletişim engellenmelidir
- Güvenlik duvarı kuralları düzenli kontrol edilmelidir

### 4. En Verimli Uygulama
- Port çakışmalarını önlemek için port planlaması yapın
- Güvenlik duvarı kurallarını dokümante edin
- Port erişimlerini düzenli monitör edin
- Gereksiz port açıklıklarından kaçının

## 3. Cluster Kurulumu

Burada, üç node örneği üzerinden anlatım yapılmıştır:  
- `rabbit@rabbit1`  
- `rabbit@rabbit2`  
- `rabbit@rabbit3`  

### 3.1 Temel Kurulum ve Node'ları Başlatma

#### İlk Kurulum
Her node'da RabbitMQ'yu normal şekilde kurup başlatın:

```bash
# rabbit1 üzerinde
rabbitmq-server -detached

# rabbit2 üzerinde
rabbitmq-server -detached

# rabbit3 üzerinde
rabbitmq-server -detached
```
#### Durum Kontrolü
Bu noktada her node, bağımsız (tek başına) bir RabbitMQ instance'ıdır. Kontrol etmek için:

```bash
rabbitmqctl cluster_status
```
#### Çıktı Örnekleri

Her node kendi çıkışında yalnızca kendisini "running_node" olarak listeler.

```bash
# Node 1 çıktısı
Cluster status of node rabbit@rabbit1 ...
[{nodes,[{disc,[rabbit@rabbit1]}]},{running_nodes,[rabbit@rabbit1]}]
...done.

# Node 2 çıktısı  
Cluster status of node rabbit@rabbit2 ...
[{nodes,[{disc,[rabbit@rabbit2]}]},{running_nodes,[rabbit@rabbit2]}]
...done.

# Node 3 çıktısı
Cluster status of node rabbit@rabbit3 ...
[{nodes,[{disc,[rabbit@rabbit3]}]},{running_nodes,[rabbit@rabbit3]}]
...done.
```

#### Önemli Noktalar
1. **Başlangıç Durumu**
  - Her node bağımsız çalışır
  - Henüz cluster oluşturulmamıştır
  - Her node kendi veritabanını yönetir
2. **Node İsimleri**
  - Her node benzersiz bir isimle çalışır
  - Format: rabbit@hostname şeklindedir
  - Hostname çözümlenebilir olmalıdır
3. **Kontrol**
  - cluster_status komutu ile durum kontrol edilir
  - Her node'un çalıştığından emin olunmalıdır
  - Loglar kontrol edilmelidir

### 3.2 İkinci Node'u Clustera Ekleme

#### Genel Bakış
Node'ları birbirine bağlamadan önce, eklenecek node'un uygulamasını durdurup resetlemek gerekir.

#### Cluster'a Node Ekleme Adımları

1. **Node'u Durdurma ve Resetleme**
```bash
# rabbit2 üzerinde
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbit1
rabbitmqctl start_app
```
Böylece ```rabbit@rabbit2```, ```rabbit@rabbit1``` ile aynı cluster'a katılır. 
2. **Cluster Durumu Kontrol Etme**
```bash
# rabbit1 veya rabbit2 üzerinde
rabbitmqctl cluster_status
```
Artık her iki node da "disc" node olarak listelenir ve "running_nodes" ikisini de içerir.

#### Önemli Noktalar

1. **Node Hazırlığı**
  - Eklenecek node durdurulmalıdır
  - Node'un veritabanı resetlenmelidir
  - Reset işlemi tüm verileri siler
2. **Cluster'a Katılma**
  - ```join_cluster``` komutu ile ana node'a bağlanılır
  - ```join_cluster``` komutu başarılı olursa, ```start_app``` komutu ile node tekrar başlatılır
  - Her iki node da "disc" node olarak listelenir
3. **Doğrulama**
  - Cluster durumu her iki node'dan kontrol edilebilir
  - "running_nodes" listesinde her iki node görünmelidir
  - Node'lar birbirlerini görebilmelidir
4. **Dikkat Edilmesi Gerekenler**
  - Reset işlemi geri alınamaz
  - Tüm veriler silinir
  - Node isimleri doğru olmalıdır
  - Portlar ve erişimler kontrol edilmelidir

### 3.3 Üçüncü Node'u Clustera Ekleme

#### Genel Bakış
İkinci node'da olduğu gibi, üçüncü node'u da cluster'a eklemek için benzer adımlar izlenir.

#### Node Ekleme Adımları

```bash
# rabbit3 üzerinde
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbit2
rabbitmqctl start_app
```

#### Önemli Noktalar

1. **Bağlantı Esnekliği**
  - rabbit@rabbit2 yerine rabbit@rabbit1 de kullanılabilir
  - Önemli olan bağlanılan node'un cluster'a üye olmasıdır
  - Herhangi bir aktif cluster üyesine bağlanılabilir
2. **Cluster Durumu**
  - Bu işlemlerden sonra üç node'lu bir cluster oluşur
  - Tüm node'lar birbirini görebilir durumda olur
  - Cluster tam olarak çalışır hale gelir
3. **Doğrulama**
  - Her node'da ```cluster_status``` komutu çalıştırılarak durum kontrol edilebilir
  - "running_nodes" listesinde üç node görünmelidir
  - Node'lar birbirlerini görebilmelidir
4. **En Verimli Uygulama**
  - Node eklemeden önce cluster durumu kontrol edilmeli
  - İşlemler sırasıyla ve dikkatle yapılmalı
  - Her adımdan sonra doğrulama yapılmalı

## 4. Node'ların Yeniden Başlatılması ve Kritik Durumlar
### 4.1 Node'u Durdurmak
```bash
rabbitmqctl stop
```
#### Durdurma Etkileri
* Quorum Queue / Stream kullanılıyorsa kuyruk lider replikaları diğer node'lara kayabilir
* Classic Queue'da mesajlar tek node'daysa, o node durduğunda kuyruğa erişim kesilir

### 4.2 Node'u Yeniden Başlatmak
* Node tekrar başlatıldığında (```rabbitmq-server -detached``` komutuyla):
  * Kapanmadan önceki senkronizasyon kaynağını hatırlar
  * Kaynak node çevrimiçiyse veri senkronize olur
  * Node cluster'a otomatik katılır
  * Senkronizasyon kaynağı kapalıysa 5 dakika sonra timeout alabilir
### 4.3 Tüm Cluster'ı Kapama ve Açma
#### Kapama Sırası
* Son kapanan node ilk açıldığında:
  * Veri senkronizasyonu gerekmez
  * Kendi veritabanını yükler
* Diğer node'lar açıldığında:
  * Mevcut bir node üzerinden senkronize olur
  * Herhangi bir aktif node'a bağlanabilir
#### Kubernetes Ortamında
* Node'ların açılış sırası önemlidir
* Readiness probe'lar düzgün konfigüre edilmelidir
* Node sağlık kontrolleri doğru yapılandırılmalıdır
### 4.4 En Verimli Uygulama
1. **Sıralı Başlatma**
   - Node'ları sıralı olarak başlatın
   - Senkronizasyon için yeterli süre verin
   - Timeout değerlerini ortama göre ayarlayın
2. **Monitoring**
   - Node'ların durumunu izleyin
   - Senkronizasyon problemlerini hızlı tespit edin
   - Log'ları düzenli kontrol edin
3. **Yedeklilik**
   - Kritik node'ları belirleyin
   - Yedek node'ları hazır tutun
   - Failover senaryolarını test edin

## 5. Node Silme, Cluster'dan Çıkarma ve Resetleme
### 5.1 Bir Node'u Cluster'dan Çıkarma
##### Node Çalışırken
```bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
```
Bu işlem, node'u bağımsız bir RabbitMQ sunucusuna çevirir. 

##### Uzak Node'u Silme

Diğer node'lardan "forget_cluster_node" komutuyla da uzak node'u silmek mümkündür:
```bash
# rabbit2 üzerinden, rabbit1'i unutmak
rabbitmqctl forget_cluster_node rabbit@rabbit1
```
Bu durumda ```rabbit@rabbit1``` tekrar ayağa kalktığında, kendini resetleyene kadar cluster'a dönemez.
### 5.2 Bir Node'u (Veri Silerek) Resetlemek
Bir node herhangi bir nedenle tutarsız hale geldiyse ya da yeniden temiz bir node olarak başlatmak istiyorsanız:
```bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
```
#### Reset İşleminin Etkileri
1. **Veri Temizliği**
    - Tüm veriler silinir
    - Kuyruklar, kullanıcılar, ayarlar vb. kaybolur
2. **Cluster İlişkisi**
    - Node cluster'dan çıkar
    - Bağımsız bir node haline gelir
3. **Yeniden Cluster'a Katılma**
    - Reset sonrası cluster'a katılmak için ```join_cluster``` komutu kullanılmalıdır
    - Yeni bir üye gibi cluster'a eklenmelidir
4. **En Verimli Uygulama**
    - Reset öncesi gerekli verilerin yedeği alınmalıdır
    - Reset işlemi geri alınamaz
    - Cluster durumu sürekli kontrol edilmelidir

## 6. Replicas, Quorum Queues ve Dengeleme

### 1. Varsayılan Kuyruklar (Classic Queues)
- Tek bir node'da tutulur
- Yedeği yoktur
- Cluster içinde her yerden görünür
- Fiziksel mesajlar tek bir node üzerindedir

### 2. Quorum Queues ve Streams
- Mesajlar birden fazla node'a replike edilir
- Node hatalarına karşı dayanıklıdır
- Çoğunluk sağlandığı sürece çalışmaya devam eder
- Klasik kuyruklara göre daha yüksek erişilebilirlik sunar

### 3. Lider Replika Yerleşimi

#### Yerleşim Stratejileri
Kuyruk veya stream oluşturulduğunda lider replikanın yerleşimi `queue_leader_locator` ayarı ile belirlenir:

1. **client-local (varsayılan)**
   - Lider replika client'ın bağlandığı node'da oluşturulur
   - Basit ve hızlı erişim sağlar

2. **balanced**
   - Daha eşit dağıtım hedeflenir
   - Sistem liderleri node'lar arasında dengeli dağıtır
   - Yük dengeleme için daha uygundur

### 4. En Verimli Uygulama

1. **Kuyruk Tipi Seçimi**
   - İş kritikliğine göre kuyruk tipi seçilmeli
   - Yüksek erişilebilirlik gereken durumlar için Quorum Queue tercih edilmeli
   - Basit işlemler için Classic Queue kullanılabilir

2. **Yerleşim Stratejisi**
   - Cluster büyüklüğüne göre strateji seçilmeli
   - Yük dengeleme ihtiyacı göz önünde bulundurulmalı
   - Performans gereksinimleri dikkate alınmalı

3. **Monitoring**
   - Kuyruk dağılımları izlenmeli
   - Node yükleri kontrol edilmeli
   - Dengesiz dağılımlar tespit edilmeli
## 7. İstemciler ve Bağlantı Yönetimi
#### Protokol Bazlı Bağlantılar

1. **Standart Protokoller**
   - AMQP, MQTT, STOMP gibi protokollerde istemci tek node'a bağlanır
   - Node hatası durumunda istemci yeniden bağlanabilir
   - Farklı bir node üzerinden devam edebilir

2. **RabbitMQ Stream Protokolü**
   - İstemci birden çok node'a bağlanabilir
   - Replikalar arasından tüketim yapabilir
   - Daha yüksek erişilebilirlik sağlar

#### Bağlantı Yönetimi En Verimli Uygulama

1. **Otomatik Failover**
   - İstemciler node listesi kullanmalı
   - Otomatik failover entegrasyonu yapılmalı
   - Bağlantı kopması durumunda alternatif node'lara geçebilmeli

2. **IP Adresi Kullanımı**
   - IP adreslerinin hard-code edilmesi önerilmez
   - Cluster yapılandırması değişebilir
   - Node sayısı değişebilir
   - Değişiklikler kod değişimi gerektirir

3. **Önerilen Yaklaşımlar**
   - Dinamik DNS servisi kullanımı (düşük TTL ile)
   - TCP load balancer kullanımı
   - Her ikisinin kombinasyonu
   - Cluster yönetimi için özel teknolojilerin kullanımı

4. **Bağlantı Yönetimi**
   - Cluster içi bağlantı yönetimi ayrı ele alınmalı
   - Özel çözümler tercih edilmeli
   - Ölçeklenebilir yapılar kurulmalı
## 8. Node'ların Yeniden Başlatılması ve Kritik Durumlar

#### 1. Node'u Durdurmak
```bash
rabbitmqctl stop
```
##### Durdurma Etkileri
* Quorum Queue / Stream kullanılıyorsa kuyruk lider replikaları diğer node'lara kayabilir
* Classic Queue'da mesajlar tek node'daysa, o node durduğunda kuyruğa erişim kesilir
#### 2. Node'u Yeniden Başlatmak
##### Başlatma Süreci
* Node tekrar başlatıldığında (rabbitmq-server -detached komutuyla):
  * Kapanmadan önceki senkronizasyon kaynağını hatırlar
  * Kaynak node çevrimiçiyse veri senkronize olur
  * Node cluster'a otomatik katılır
  * Senkronizasyon kaynağı kapalıysa 5 dakika sonra timeout alabilir
#### 3. Tüm Cluster'ı Kapama ve Açma
##### Kapama/Açma Sırası
* Son kapanan node ilk açıldığında:
  * Veri senkronizasyonu gerekmez
  * Kendi veritabanını yükler
* Diğer node'lar:
  * Mevcut bir node üzerinden senkronize olur
  * Herhangi bir aktif node'a bağlanabilir
* Kubernetes Ortamında
  * Node'ların açılış sırası önemlidir
  * Readiness probe'lar düzgün konfigüre edilmelidir
  * Node sağlık kontrolleri doğru yapılandırılmalıdır
#### 4. En Verimli Uygulama
1. **Sıralı İşlemler**
    * Node'ları kontrollü şekilde başlatın/durdurun
    * Senkronizasyon için yeterli süre verin
    * Timeout değerlerini ortama göre ayarlayın

2. **İzleme**
    * Node durumlarını sürekli monitör edin
    * Senkronizasyon problemlerini hızlı tespit edin
    * Log'ları düzenli kontrol edin
3. **Yedeklilik**
    * Kritik node'ları belirleyin
    * Yedek node'ları hazır tutun
    * Failover senaryolarını test edin
## 9. Önemli Notlar
#### 1. İki Node'lu Cluster Kullanımı
- Kesinlikle önerilmez
- Çoğunluk sağlanamadığında sistem çöker
- Kuyruklar devre dışı kalabilir

#### 2. Veri Kaybı Riskleri
- Reset işlemlerinde kalıcı kuyruk mesajları silinebilir
- Yanlış yapılandırma veri kaybına neden olabilir
- Production ortamında her adım dikkatle uygulanmalı

#### 3. WAN Ortamında Cluster
- Farklı veri merkezleri arasında cluster önerilmez
- Bunun yerine kullanılabilecek alternatifler:
  - Federation eklentisi
  - Shovel eklentisi

#### 4. Yükseltme ve Versiyon Uyumluluğu
- Tüm node'larda aynı Erlang/OTP ana sürümü kullanılmalı
- Tüm node'larda aynı RabbitMQ sürümü kullanılmalı
- Versiyon uyumsuzlukları sorunlara yol açabilir

#### 5. En Verimli Uygulama

1. **Cluster Planlaması**
   - Node sayısı dikkatli belirlenmeli
   - Tek sayıda node tercih edilmeli
   - Yedeklilik planlanmalı

2. **Versiyon Yönetimi**
   - Sürüm geçişleri planlanmalı
   - Uyumluluk kontrol edilmeli
   - Yükseltmeler test edilmeli

3. **Network Yapılandırması**
   - WAN yerine LAN tercih edilmeli
   - Ağ gecikmeleri minimize edilmeli
   - Güvenlik duvarı kuralları düzenlenmeli
## 10. Sonuç
#### Genel Bakış
Bu dokümantasyon ile RabbitMQ üzerinde:
- Yedekli (cluster) bir yapı kurabilirsiniz
- Node'ları ekleyip çıkarabilirsiniz  
- Veri bütünlüğünü koruyabilirsiniz
- Yüksek erişilebilirlik senaryolarını yönetebilirsiniz

#### Yüksek Erişilebilirlik Özellikleri

1. **Quorum Queues**
   - Mesajları birden fazla node'a çoğaltabilir
   - Node hatalarında veri kaybını minimize eder
   - Çoğunluk tabanlı konsensüs sağlar

2. **RabbitMQ Stream**
   - Yüksek performanslı replikasyon
   - Ölçeklenebilir mesaj akışı
   - Dayanıklı veri saklama

#### En Verimli Uygulama

1. **Cluster Yönetimi**
   - Node sayısını dikkatli planlayın
   - Yedeklilik stratejisi belirleyin
   - Monitoring çözümü kurun

2. **Veri Güvenliği**
   - Düzenli yedekleme yapın
   - Felaket kurtarma planı oluşturun
   - Veri tutarlılığını kontrol edin

3. **Performans**
   - Node'ları dengeli dağıtın
   - Kaynak kullanımını izleyin
   - Darboğazları tespit edin