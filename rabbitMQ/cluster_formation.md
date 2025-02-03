# Cluster Oluşumu ve Peer Discovery (Akran Keşfi)

Bu bölüm, RabbitMQ'nun otomasyon odaklı cluster oluşumu ve peer discovery (akran keşfi) özelliklerini ele alır. Özetle:

- **Cluster Oluşumu:**  
  RabbitMQ cluster'ının kurulmasıyla ilgili süreçleri kapsar. Yeni (boş) node'lar, varolan cluster üyelerini (peer'leri) keşfederek cluster'a dahil olurlar. Bu süreçte, bir node veritabanı henüz başlatılmamışsa, yapılandırılmış peer discovery mekanizması ile diğer düğümleri tespit eder ve ilk erişilebilen peer ile cluster'a katılır.

- **Peer Discovery (Akran Keşfi):**  
  Cluster formation sürecinin temel bir bileşenidir. Yeni katılan bir node'un mevcut cluster üyeleriyle iletişim kurabilmesi için kullanılır. Bu mekanizma, çeşitli yöntemlerle (örneğin yapılandırma dosyasında belirtilen statik liste, DNS, AWS, Kubernetes, Consul veya etcd gibi eklenti tabanlı çözümler) uygulanabilir. Her mekanizma, node'ların birbirleriyle gerekli iletişimi kurabilmesi ve doğrulama yapabilmesi için belirli ayarları ve konfigürasyonları gerektirir.

Bu sayede, RabbitMQ cluster'ının oluşturulması sırasında otomatik keşif ve katılım sağlanır; node'lar uygun şekilde senkronize edilerek tek bir bütün olarak çalışır.

# Genel Bakış

Bu rehber, otomasyona dayalı cluster (küme) oluşumu ve akran keşfi (peer discovery) özelliklerine genel bir bakış sunar. RabbitMQ clustering hakkında genel bir perspektif için Clustering Guide (Kümeleme Kılavuzu) referans alınmalıdır.

Rehber, RabbitMQ clustering konusunda genel bir aşinalığı varsayar ve özellikle akran keşfi alt sistemine odaklanır. Bu nedenle; node'lar arası iletişimde hangi portların açık olması gerektiği, node'ların birbirleriyle nasıl kimlik doğrulaması gerçekleştirdiği gibi konulara değinilmemiştir.

Ayrıca, rehber; keşif mekanizmaları ve yapılandırmalarıyla birlikte; cluster oluşumu sırasında belirli özelliklerin erişilebilirliği, node'ların yeniden katılım süreçleri, paralel olarak başlatılan node'larda oluşabilecek ilk cluster kurulum problemleri ve bazı keşif implementasyonlarının sunduğu ek sağlık kontrolleri gibi konuları kapsamaktadır.

Son olarak, akran keşfi ile ilgili temel sorun giderme adımlarına da yer verilir.

# Peer Discovery Nedir?

Cluster oluşturulurken, "boş" (henüz cluster'a katılmamış) bir node'un, mevcut cluster üyelerini (peer'leri) keşfedebilmesi için kullanılan mekanizmaya "Peer Discovery" denir. Bu mekanizma sayesinde:

- Yeni node'lar, cluster içindeki diğer node'ları tespit ederek onlarla iletişim kurabilir.
- Bazı yöntemler, tüm cluster üyelerinin önceden bilindiği (örneğin, konfigürasyon dosyasında listelenmiş) statik yapılandırmalara dayanırken; bazı yöntemler, node'ların dinamik bir şekilde eklenip çıkarılabileceği esnek sistemlere dayalıdır.
- Tüm peer discovery mekanizmaları, yeni eklenen node'un cluster içerisindeki arkadaşlarını bulup başarılı bir şekilde onlarla kimlik doğrulaması yapmasını varsayar.
- DNS, Consul, AWS, Kubernetes gibi dış servis veya API tabanlı mekanizmalar kullanıldığında, ilgili hizmetlerin standart portlar üzerinden erişilebilir olması gerekir. Aksi halde, servislerin ulaşılamaması node'un cluster'a katılamamasına yol açar.

Bu yapı, otomatik bir küme oluşumu sürecinde node'ların birbirlerini hızlı ve güvenilir şekilde bulmalarını sağlar.

# Kullanılabilir Keşif Mekanizmaları

RabbitMQ'nun cluster formation sürecinde node'ların birbirlerini otomatik olarak tespit edebilmesi için çeşitli yerleşik ve eklenti tabanlı (plugin) keşif mekanizmaları mevcuttur. Bu mekanizmalar, farklı ortam ihtiyaçlarına göre esneklik sağlar:

## Yerleşik Mekanizmalar

- **Konfigürasyon Dosyası (Config file):**  
  Cluster üyeleri, yapılandırma dosyasında statik olarak tanımlanır. Node'lar, bu dosyadan okunacak liste aracılığıyla birbirlerini keşfeder.
- **Önceden Yapılandırılmış DNS A/AAAA Kayıtları:**  
  Belirlenmiş “seed” (tohum) hostname ile DNS sunucusundan alınan A veya AAAA kayıtları kullanılarak node'lar tespit edilir. DNS üzerinde yapılan sorgulamalar, ilgili IP adreslerinden node isimlerini elde etmeye yardımcı olur.

## Eklenti Tabanlı Ek Mekanizmalar

RabbitMQ, ek peer discovery mekanizmalarını çeşitli plugin'ler aracılığıyla sunar. Ancak bu pluginlerin kullanılabilmesi için, öncelikle etkinleştirilmiş ya da yapılandırılmış olmaları gerekmektedir:

- **AWS (EC2):**  
  AWS ortamında EC2 instance'ları üzerinden keşif yapılabilir. Bu mekanizma; EC2 instance etiketleri veya otomatik ölçeklendirme (autoscaling) grubundaki üyelik bilgileri kullanılarak çalışır.
- **Kubernetes:**  
  Kubernetes API'si kullanılarak, cluster ortamındaki pod'lar arası dinamik keşif sağlanır. Kubernetes ortamında deploy edilen RabbitMQ node'ları, API'den alınan bilgi sayesinde birbirlerini tespit eder.
- **Consul:**  
  Consul tabanlı keşif mekanizması, node'ların Consul servis kayıtları ve sağlık kontrolü bilgilerini kullanır. Node'lar, Consul üzerinde kayıtlı servis bilgilerinden yararlanarak cluster oluşturulmasına katkıda bulunur.
- **etcd:**  
  Etcd, gRPC tabanlı client aracılığıyla çalışır. Node'lar, etcd üzerinde önceden belirlenmiş anahtarlar altında kendilerini kaydeder ve diğer node’lar bu kayıtlar üzerinden keşfedilir.

Bu mekanizmaların her biri, ortamınıza ve ihtiyaçlarınıza göre statik ya da dinamik keşif çözümleri sunar; böylece RabbitMQ cluster'ınızın kurulumu ve yönetimi esnek bir biçimde gerçekleştirilebilir.

# Keşif Mekanizmasının Belirlenmesi

Bu bölümde, RabbitMQ'nun cluster oluşturma sürecinde kullanılacak olan "peer discovery" (akran keşfi) mekanizmasının konfigürasyon dosyasında nasıl belirtileceği açıklanmaktadır.

- Kullanılacak keşif mekanizması, konfigürasyon dosyasında tanımlanır.
- "cluster_formation.peer_discovery_backend" anahtarının değeri, hangi keşif modülünün (uygulamasının) kullanılacağını belirler.
- Örneğin, klasik yapılandırma yöntemini kullanmak için ayar şu şekilde yapılır:

  ```erlang
  cluster_formation.peer_discovery_backend = classic_config
  ```

- Ayrıca, backend'i belirtmek için modül adı da kullanılabilir. Ancak, modül isimlerinin eklenti (plugin) isimleriyle birebir eşleşmediğini unutmayın. Bu nedenle aşağıdaki satır da aynı işlevi görebilir:

  ```erlang
  cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
  ```

Bu yapılandırma, RabbitMQ cluster'ında kullanılacak olan akran keşfi mekanizmasını belirler ve ilgili mekanizmaya özgü diğer ayarların (ör. keşif hizmeti host adları, kimlik bilgileri vb.) tanımlanmasında temel rol oynar.

# Akran Keşfi Nasıl Çalışır?

Bir RabbitMQ düğümü (node) başlatıldığında, daha önce başlatılmış bir veritabanına (örneğin, initialized veritabanı) sahip olup olmadığını kontrol eder. Eğer veritabanı başlatılmamışsa, yapılandırılmış bir akran keşfi mekanizmasının tanımlı olup olmadığını inceler. Bu durumda işlem şu şekilde ilerler:

- **Keşif İşleminin Başlatılması:**  
  Düğüm, konfigürasyon dosyasında belirtilmiş olan akran keşfi mekanizmasını aktif hale getirir. Bu mekanizma, düğümün mevcut cluster üyesi olabilecek diğer düğümleri tespit etmek için devreye girer.

- **Potansiyel Peer Düğümlerin Belirlenmesi:**  
  Keşif işlemi, statik olarak konfigürasyonda yer alan düğüm listesinden ya da DNS, AWS, Kubernetes, Consul, etcd gibi dış servislerden gelen dinamik bilgilerden yararlanarak, cluster'a katılabilecek peer düğümleri belirler.

- **İletişime Geçme ve Doğrulama:**  
  Düğüm, keşfedilen her peer düğüm ile sırayla iletişim kurmaya çalışır. İlk ulaşılabilir düğüm tespit edildiğinde, bu düğümle bağlantı kurulup cluster'a katılma girişimi yapılır.

- **Kayıt (Registration) Süreci:**  
  Bazı mekanizmalar, örneğin Consul ve etcd, düğümlerin kendilerini kayıt ettiklerini varsayar. Düğüm, kendisinin aktif olduğunu bildirir; böylece cluster üyeleri listesine eklenir. Diğer mekanizmalarda düğümlerin listesi önceden tanımlanmış olur ve kayıt işlemi desteklenmez.

- **Hata ve Tekrar Deneme Durumları:**  
  Eğer yapılandırılmış akran keşfi mekanizması yoksa, sürekli başarısız olursa veya hiçbir peer düğüme ulaşılamazsa, daha önce bir cluster üyesi olmayan düğüm sıfırdan başlatılır ve bağımsız (standalone) olarak çalışmaya devam eder. Tüm bu adımlar düğüm loglarına işlenir.

- **Yeniden Katılım Senaryosu:**  
  Daha önce cluster üyesi olan düğümlerde, düğüm yeniden başlatıldığında akran keşfi mekanizması devreye girmez. Bunun yerine, "son görülen" (last seen) peer düğümüne bağlanarak eski cluster yapılandırması üzerinden yeniden katılma girişiminde bulunur.

Bu sayede, yeni veya yeniden başlatılan düğümler, yapılandırılmış akran keşfi mekanizması sayesinde mevcut cluster üyelerini tespit eder ve otomatik olarak cluster'a katılarak dağıtık yapının bütünlüğünü korur.

# Cluster Oluşumu ve Özelliklerin Erişilebilirliği

Bu bölümde, cluster'ın henüz tamamen oluşturulmamış olsa dahi (yani yalnızca bazı düğümlerin katıldığı durumlarda) client'lar tarafından tam erişilebilir kabul edilmesi gerektiği anlatılır.

- **Kademeli Cluster Oluşumu:**  
  Cluster oluşturma süreci henüz tamamlanmamış olsa dahi, client'lar mevcut node'larla bağlantı kurar. Bu nedenle, cluster'ın tam formasyonunun gerçekleşmemiş olması, sistemin temel hizmetleri vermesini engellemez.

- **Node Bağlantıları:**  
  Bireysel düğümler, cluster tam olarak oluşturulmadan bile client bağlantılarını kabul eder. Ancak bu durumda, bazı gelişmiş özellikler (örneğin quorum kuyrukları) henüz aktif olmayabilir.

- **Özellik Kullanılabilirliği:**  
  Örneğin, quorum kuyrukları, cluster'da yeterli sayıda node (yapılandırılmış replikasyon çoğunluğunu sağlayacak sayıda) bulunmadığı sürece kullanılabilir olmayacaktır. Benzer şekilde, özellik bayrakları (feature flags) ile kontrol edilen ek özellikler de cluster formasyonu tamamlanana kadar devre dışı kalabilir.

Bu yaklaşım, cluster'ı kademeli olarak oluşturan ortamlarda, client'ların sistemle etkileşimde bulunmasını sağlarken, belirli gelişmiş hizmetlerin ancak cluster tamamlandığında aktif hale gelmesine olanak tanır.

# Mevcut Cluster'a Yeniden Katılma

Bir node daha önce bir cluster üyesiyse, yeniden başlatıldığında veya kısa süreli bağlantısını kaybettikten sonra kendi kendine "peer discovery" gerçekleştirmez. Bunun yerine, daha önce kayıt altına alınmış "son görülmüş" (last seen) peer ile doğrudan iletişim kurarak cluster'a katılmaya çalışır.

- **Otomatik Yeniden Katılma Süreci:**  
  Node, yeniden başlatıldığında belirli bir süre boyunca (varsayılan 10 deneme, her deneme 30 saniye aralıkla; toplamda yaklaşık 5 dakika) son kayıtlı peer ile bağlantı kurmaya çalışır. Bu süre zarfında peer'den yanıt alınırsa, node cluster'a başarıyla yeniden katılır.

- **Bağlantı Sorunları Durumunda:**  
  Eğer, belirlenen süre boyunca veya yapılan denemeler sonucunda son görülen peer ile bağlantı kurulamazsa, node yeniden katılma işlemini tekrarlamak zorunda kalır. Bu durumda node, önceki üye statüsünü kaybetmiş gibi davranabilir.

- **Node Resetlenmişse:**  
  Eğer node, cluster ile iletişimi kesildikten sonra resetlenmişse, başlangıçta boş (yeni) bir node gibi davranır. Böyle durumda diğer cluster üyeleri onu hâlâ eski üye olarak değerlendiriyorsa, uyumsuzluk ortaya çıkabilir ve node cluster'a katılamaz. Böyle bir durumda operatörün "rabbitmqctl forget_cluster_node" komutuyla bu node'u cluster listesinden temizlemesi gerekir.

- **Operatör Tarafından Çıkarılan Node'lar:**  
  Eğer node operatör tarafından cluster'dan açıkça çıkarılmışsa ve sonrasında resetlenirse, bu node yeni bir üye olarak cluster'a katılmaya çalışır; yani ilk kez katılan bir node gibi davranır.

- **İsim veya Host Adı Değişikliği:**  
  Node ismi veya host adı değişikliği, veri dizini yolunun da değişmesine neden oluyorsa, node cluster'a yeniden katılma girişimi boş (yeni) node olarak değerlendirilecektir. Bu durum, dahili veri deposundaki cluster kimliğinin artık eşleşmemesine sebep olur ve node'un cluster'a katılması başarısız olur.

Bu mekanizma, yeniden başlatılan veya kesintiye uğrayan node'ların durumu ile ilgili uyumsuzlukların önüne geçmeyi ve cluster bütünlüğünü korumayı hedefler.

# Peer Discovery Yapılandırması

Bu bölüm, RabbitMQ'da cluster oluşumu sırasında kullanılacak "peer discovery" mekanizmasının nasıl yapılandırılacağına dair genel bir rehber sunar. Kullanılabilecek yapılandırma seçenekleri, ortamın gereksinimlerine göre farklı back-end’ler kullanarak düğümlerin birbirlerini otomatik olarak tespit edebilmesini sağlar. Aşağıda, her bir mekanizma için örnek konfigürasyonlar ve açıklamalar yer almaktadır.

---

## 1. Config File (Konfigürasyon Dosyası) Peer Discovery Backend

- **Açıklama:**  
  En temel yöntem, düğümlerin keşif listesinin statik olarak konfigürasyon dosyasında tanımlanmasıdır. Bu yöntem ile cluster üyesi olacak düğümlerin isimleri önceden belirlenir.

- **Örnek Konfigürasyon:**

  ```erlang
  cluster_formation.peer_discovery_backend = classic_config
  cluster_formation.classic_config.nodes.1 = rabbit@hostname1.eng.example.local
  cluster_formation.classic_config.nodes.2 = rabbit@hostname2.eng.example.local
  ```

## 2. DNS Peer Discovery Backend

- **Açıklama:**  
  DNS A veya AAAA kayıtlarını kullanarak, önceden belirlenmiş bir “seed” hostname üzerinden düğümler tespit edilir. DNS tabanlı yapılandırmada, ilgili DNS kayıtlarının doğru yapılandırılmış olması kritik önem taşır.
- **Örnek Konfigürasyon:**

  ```erlang
  cluster_formation.peer_discovery_backend = dns
  cluster_formation.dns.hostname = discovery.eng.example.local
  ```

## 3. AWS (EC2) Peer Discovery Backend

AWS ortamında, EC2 instance'ları için farklı keşif yöntemleri uygulanabilir:

**a) Autoscaling Group Membership Kullanımı:**

- **Açıklama:**  
  EC2 instance’larının otomatik ölçeklendirme grubundaki üyelikleri esas alınır. AWS API’leri kullanılarak, grubun üyeleri tespit edilir ve cluster üyesi olarak listeye eklenir.

- **Örnek Konfigürasyon:**

  ```erlang
  cluster_formation.peer_discovery_backend = aws
  cluster_formation.aws.region = us-east-1
  cluster_formation.aws.access_key_id = ANIDEXAMPLE
  cluster_formation.aws.secret_key = WjalrxuTnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY
  cluster_formation.aws.use_autoscaling_group = true
  ```

  **b) EC2 Instance Tags Kullanımı:**

- **Açıklama:**  
  Belirlenen EC2 instance etiketleri ile filtreleme yapılır. Bu yöntem sayesinde, sadece belirli etiketlere sahip instance'lar cluster üyesi olarak seçilir.
- **Örnek Konfigürasyon:**

  ```erlang
  cluster_formation.peer_discovery_backend = aws
  cluster_formation.aws.region = us-east-1
  cluster_formation.aws.access_key_id = ANIDEXAMPLE
  cluster_formation.aws.secret_key = WjalrxuTnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY
  cluster_formation.aws.instance_tags.region = us-east-1
  cluster_formation.aws.instance_tags.service = rabbitmq
  cluster_formation.aws.instance_tags.environment = staging
  ```

## 4. Peer Discovery on Kubernetes

- **Açıklama:**  
  Kubernetes ortamında, RabbitMQ düğümleri Kubernetes API’si kullanılarak birbirlerini tespit eder. API erişim bilgileri (host, port, token, sertifika vb.) konfigürasyon dosyasında belirtilir. Ayrıca Düğümlerin kullanacağı adres tipi (hostname veya IP) seçilebilir.
- **Örnek Konfigürasyon:**

  ```erlang
  cluster_formation.peer_discovery_backend = k8s
  cluster_formation.k8s.host = kubernetes.default.example.local
  cluster_formation.k8s.port = 443
  cluster_formation.k8s.scheme = https
  cluster_formation.k8s.token_path = /var/run/secrets/kubernetes.io/serviceaccount/token
  cluster_formation.k8s.cert_path = /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  cluster_formation.k8s.namespace_path = /var/run/secrets/kubernetes.io/serviceaccount/namespace
  cluster_formation.k8s.address_type = hostname
  ``
  ```

## 5. Peer Discovery Using Consul

- **Açıklama:**  
  Consul tabanlı peer discovery, düğümlerin Consul üzerinde kendilerini kaydetmeleri ve diğer düğümlerin bu kayıtları okuyarak tespit edilmesi prensibine dayanır. Consul’ın host, port, ACL token gibi ayarları yapılandırılır.
- **Örnek Konfigürasyon:**

  ```erlang
  cluster_formation.peer_discovery_backend = consul
  cluster_formation.consul.host = consul.eng.example.local
  cluster_formation.consul.port = 8500
  cluster_formation.consul.acl_token = acl-token-value
  cluster_formation.consul.svc = rabbitmq
  ```

## 6. Peer Discovery Using Etcd

- **Açıklama:**  
  Etcd ile yapılan peer discovery’de, düğümler etcd üzerinde belirli bir key prefix altında kendilerini kaydederler. Bu anahtarlar TTL ile yönetilir, düğümler düzenli olarak mevcut olduklarını bildirir ve lock mekanizması ile yarış durumları azaltılır.

- **Örnek Konfigürasyon:**

  ```erlang
  cluster_formation.peer_discovery_backend = etcd
  cluster_formation.etcd.endpoints.1 = one.etcd.eng.example.local:2379
  cluster_formation.etcd.endpoints.2 = two.etcd.eng.example.local:2479
  cluster_formation.etcd.endpoints.3 = three.etcd.eng.example.local:2579
  cluster_formation.etcd.username = rabbitmq
  cluster_formation.etcd.password = s3kR37
  cluster_formation.etcd.node_ttl = 40
  ```

  Her back-end, kendi dinamiklerine ve ortam gereksinimlerine göre ek ayarlamalar sunar. Bu nedenle kullanılacak yöntem, ortamınızın özelliklerine, güvenlik gereksinimlerine ve operasyonel ihtiyaçlara bağlı olarak seçilmeli ve ilgili parametreler özenle yapılandırılmalıdır.

# İlk Cluster Oluşumu Sırasında Yarış Koşulları

Başarılı bir cluster kurulumu için, başlangıçta yalnızca tek bir node'un bağımsız (standalone) olarak başlatılıp veritabanını inşa etmesi gerekmektedir. Eğer bu durum sağlanamazsa, operatör beklediği tek cluster yerine birden fazla bağımsız cluster oluşur ve bu durum istenmeyen sonuçlara yol açar.

Özellikle tüm node'ların paralel olarak başlatıldığı senaryolarda doğal bir yarış koşulu meydana gelir. Bu yarış koşullarını önlemek için kullanılan yöntemler şunlardır:

- **Paralel Başlangıç ve Yarış Koşulları:**  
  Tüm node'lar aynı anda başlatılırsa, her biri kendi başına cluster'ı başlatmaya çalışabilir. Bu durum, birden fazla bağımsız cluster oluşumuna sebep olarak sistem tutarlılığını bozar.

- **Kilitleme Mekanizması Kullanımı:**  
  Yarış koşullarının etkisini azaltmak amacıyla, peer discovery (akran keşfi) arka uçları cluster oluşturma (seeding) veya bir peer'e katılma sırasında bir kilit edinmeye çalışır. Kilitleme sayesinde aynı anda yalnızca bir node cluster'ı başlatır ve diğerleri mevcut cluster'a katılmaya çalışır.

- **Arka Uçlara Göre Kilit Kullanım Şekilleri:**
  - **Klasik Konfigürasyon, Kubernetes (K8s) ve AWS Arka Uçları:**  
    Bu yöntemlerde, çalışma zamanı tarafından sağlanan dahili bir kilitleme kütüphanesi kullanılır.
  - **Consul Tabanlı Peer Discovery:**  
    Consul üzerinde bir kilit ayarlanarak, yarış koşulu engellenmeye çalışılır.
  - **etcd Tabanlı Peer Discovery:**  
    vs. etcd üzerinde bir kilit mekanizması kullanılarak, aynı anda birden fazla node'un cluster oluşturması engellenir.

Bu mekanizmalar, başlangıçta oluşabilecek yarış koşullarını minimize eder ve tüm node'ların tek, uyumlu bir cluster oluşturmasını sağlar.

# Node Sağlık Kontrolleri ve Zorla Kaldırma

RabbitMQ cluster'larında, peer discovery mekanizması kullanılarak oluşturulan yapıda, bazı node'lar arızalanabilir, erişilemez hale gelebilir veya kalıcı olarak devreden çıkarılabilir (decommissioned). Operatörler, belirli bir süre sonunda erişilemeyen node'ların otomatik olarak cluster'dan kaldırılmasını isteyebilir; ancak, bu zorla kaldırma işlemi beklenmeyen yan etkilere yol açabilir. Bu nedenle, RabbitMQ zorla kaldırmayı varsayılan olarak uygulamaz ve bu özelliğin kullanımı çok dikkatli yapılmalıdır.

Örneğin, AWS backend'iyle yapılandırılmış bir cluster'da, bir EC2 instance'ı arızalanıp tekrar yeni bir node olarak oluşturulduğunda, orijinal "incarnation" artık kalıcı olarak erişilemez bir node olarak algılanabilir.

Dinamik node yönetimi sunan (AWS, Kubernetes, Consul, etcd) peer discovery backendlere sahip ortamlarda, cluster'da olmayan veya erişilemeyen node'lar loglanabilir veya zorla kaldırılabilir.

Özellikle uyumlu bir peer discovery plugin etkinleştirilmişse, aşağıdaki ayarlar kullanılabilir:

- **Sadece Uyarı Loglarını Yazdırma (Varsayılan):**

  ```erlang
  cluster_formation.node_cleanup.only_log_warning = true
  ```

- **Zorla Node Kaldırma:**
  ```erlang
  cluster_formation.node_cleanup.only_log_warning = false
  ```
  Bu durumda, kaldırılan node'lar yeniden cluster'a katılamaz. Bu seçeneğin özellikle AWS dışındaki discovery backendlere karşı dikkatle kullanılması gerekmektedir.

Ayrıca, otomatik temizleme kontrolleri periyodik olarak gerçekleştirilir. Varsayılan olarak bu kontrol aralığı 60 saniyedir; fakat aşağıdaki ayar ile bu süre 90 saniyeye çıkarılabilir:

```erlang
cluster_formation.node_cleanup.interval = 90000
```

# Akran Keşfi Hataları ve Tekrar Denemeleri

Yeni bir node, cluster'a katılmaya çalışırken ya da cluster oluşturulurken, akran keşfi işlemi başarısız olursa, RabbitMQ otomatik olarak belirli sayıda ve belirlenmiş aralıklarla tekrar deneme yapar. Bu mekanizma, düğümlerin yeniden başlatıldığında gerçekleştirdiği peer senkronizasyonundaki (peer sync) tekrar denemelere benzer.

Örneğin:

- **Kubernetes**: Pod listesini elde etmek için yapılan API istekleri, eğer başarısız olursa, belirli bir gecikme (örneğin 500 ms) ile tekrar denenir.
- **AWS (EC2)**: EC2 API üzerinden yapılan çağrılar da benzer şekilde tekrar denenir.

Bu tekrar deneme mekanizması:

- Geçici hizmet aksaklıkları (DNS, Consul, etcd gibi) veya API uç noktalarındaki yavaşlıklardan kaynaklanan sorunların etkisini azaltmaya yardımcı olur.
- Ancak, düğümler arası kimlik doğrulaması gibi temel problemlerde yapılan tekrarlar, cluster oluşumunun kaçınılmaz olarak başarısız olmasına neden olabilir.

Varsayılan ayarlar şunlardır:

- **Tekrar Deneme Limiti**: 10
- **Tekrar Deneme Aralığı**: 500 milisaniye

Başarısız deneme durumunda, düğüm loglarında kalan tekrar sayısı ve deneme gecikmeleri ile ilgili uyarılar kaydedilir. Bu sayede operatörler, peer discovery sürecinde meydana gelen sorunları tespit edip gerekli müdahaleyi gerçekleştirebilir.

# HTTP Proxy Ayarları

Peer discovery mekanizmaları, AWS, Consul, etcd gibi bağımlılar ile HTTP üzerinden iletişim kurduğunda, bu isteklerini isteğe bağlı olarak bir HTTP proxy sunucusu aracılığıyla gerçekleştirebilir. Bu, ağ yapılandırmanıza ve güvenlik politikalarınıza bağlı olarak HTTP isteklerinin istenen proxy üzerinden yönlendirilmesini sağlar.

## Ayar Detayları

- **HTTP ve HTTPS Proxy Ayarları:**  
  Proxy sunucuları, HTTP ve HTTPS istekleri için ayrı ayrı tanımlanabilir. Ortamınıza uygun proxy sunucu IP adresleri girilmelidir. Örneğin:

  ```erlang
  cluster_formation.proxy.http_proxy = 192.168.0.98
  cluster_formation.proxy.https_proxy = 192.168.0.98
  ```

* **Proxy Hariç Bırakılacak Hostlar:**  
  Bazı hostlara yapılan isteklerin doğrudan hedefe gitmesi gerekebilir. Örneğin, AWS Instance Metadata gibi link-local IP adresleri ya da proxy üzerinden yönlendirilmesinin istenmediği alan adları aşağıdaki şekilde hariç tutulabilir:
  ```erlang
  cluster_formation.proxy.proxy_exclusions.1 = 169.254.169.254
  cluster_formation.proxy.proxy_exclusions.2 = excluded.example.local
  ```

## Kullanım Amacı

- **Ağ Güvenliği ve Yönetimi:**
  HTTP istekleri güvenlik duvarları veya kurumsal ağ politikaları gereği belirli bir proxy üzerinden yönlendirilebilir.

- **Performans ve Erişilebilirlik:**
  Proxy ayarları, dış servislere (örneğin AWS API, Consul veya etcd) yapılan isteklerin yönetilmesini ve gerektiğinde belirli hostlar için doğrudan bağlantı kurulmasını sağlar.

Bu ayarlar, RabbitMQ'nun peer discovery gibi HTTP kullanan mekanizmalarında, ilgili dış servislerle iletişimin proxy üzerinden yönetilmesi için yapılandırılır.

# Sorun Giderme

Peer discovery alt sistemi ve mekanizma uygulamaları, keşif sürecine ilişkin önemli adımları **info** log seviyesinde kaydeder. Daha ayrıntılı bilgiye ihtiyaç duyulduğunda ise **debug** log seviyesinde daha kapsamlı kayıtlar elde edilebilir. Özellikle HTTP tabanlı servislerle iletişim kuran mekanizmalar, yapılan tüm giden HTTP isteklerini ve alına yanıt kodlarını **debug** seviyesinde loglar.

Eğer loglarda, mekanizmanın düğümleri keşfetmeye başladığını veya clustering denemelerinin gerçekleştiğine dair herhangi bir kayıt bulunmuyorsa, bu durum şu senaryolardan kaynaklanıyor olabilir:

- Node'un veri dizini zaten başlatılmış olduğundan dolayı yeni peer discovery işlemi gerçekleştirilmemektedir.
- Node daha önceden cluster üyesi olduğundan, peer discovery süreci atlanmaktadır.

Ayrıca, peer discovery işleminin başarılı olabilmesi için, tüm node’ların birbirleriyle ağ üzerinden iletişim kurabilmeleri ve aynı paylaşılan gizli anahtarı (Erlang cookie) kullanarak kimlik doğrulaması yapabilmeleri gerekmektedir. Bu nedenle, sorun giderme sürecinde:

- Node'lar arası ağ bağlantılarının sorunsuz olduğunu,
- Tüm node’ların aynı Erlang cookie değerini paylaştığını kontrol etmek önemlidir.

Sorun giderme sürecinde ağ bağlantısı ve ilgili yapılandırmalar konusunda daha detaylı adımlar için, "Network Connectivity Troubleshooting" rehberine başvurabilirsiniz.
