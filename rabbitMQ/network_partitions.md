# Kümeleme ve Ağ Bölünmeleri: Kılavuzun Genel Kapsamı ve Amaçları

Bu kılavuz, kümeleme yapısı içerisindeki belirli bir konuyu ele alır; yani, cluster üyeleri arasında yaşanabilecek ağ bağlantısı kesintilerinin (ağ bölünmeleri) etkileri ve bu durumlarla başa çıkma yöntemleri konusudur. Genel olarak kılavuzun amaçları şunlardır:

- **Ağ Bağlantısı Kesintilerinin Tespiti:**  
  Cluster üyeleri arasında bağlantı koptuğunda, örneğin 60 saniye gibi bir sürede iletişim sağlanamadığında, bu durum ağ bölünmesi olarak algılanır. Bu kesintiler, RabbitMQ logları, HTTP API çıktıları ve CLI komutları ile tespit edilebilir.

- **Ağ Bölünmelerinin Etkileri ve Split-Brain Durumu:**  
  Ağ bölünmeleri sırasında, cluster üyelerinin iki veya daha fazla gruba ayrılarak bağımsız işlemlere başlaması; yani her grubun diğer grubu başarısız olarak değerlendirip, ayrı ayrı gelişmeye gitmesi (split-brain) söz konusu olabilir. Bu durum, veri tutarlılığı ve sistem kullanılabilirliği üzerinde önemli etkilere neden olur.

- **Bölünme Yönetim Stratejileri:**  
  Uygulamanın veri tutarlılığı ve erişilebilirlik taleplerine bağlı olarak, farklı ağ bölünmesi yönetim stratejileri uygulanabilir. Örneğin:  
   - _pause-minority_: Ağ bölünmesi oluştuğunda, azınlıkta kalan düğümler otomatik olarak duraklatılır.  
   - _pause-if-all-down_: Belirli düğümlerin tamamı ulaşılamadığında işlemler duraklatılır.  
   - _autoheal_: Bölünme sonlandığında, otomatik olarak en sağlıklı parti seçilerek diğer düğümler yeniden başlatılır.

- **Kümeleme Amaçları ve Avantajları:**  
  Kümeleme; replikasyon yoluyla veri güvenliği, artan müşteri operasyonları erişilebilirliği ve genel yüksek sistem verimliliği gibi çeşitli hedefler doğrultusunda kullanılır. Bu kılavuz, ağ bölünmelerinin bu hedefler üzerindeki potansiyel etkilerini anlamanıza ve uygun kurtarma yöntemlerini uygulamanıza yardımcı olmayı hedefler.

# Ağ Bölünmelerini Tespit Etme

Ağ bölünmelerinin tespiti, cluster içerisindeki node'ların birbirleriyle olan iletişim kesintilerinin analiz edilmesiyle sağlanır. Aşağıda, bu tespit yöntemleri ayrıntılı olarak açıklanmıştır:

## Nodlar Arası İletişim Kesintilerinin Algılanması

- **İletişim Süresi:**  
  Varsayılan olarak, bir node diğer bir node ile 60 saniye boyunca iletişim kuramazsa, bu node'nun kapalı olduğu kabul edilir.
- **Çift Taraflı Algılama:**  
  İki node, birbirleriyle iletişim kuramadığında ve her iki taraf da karşı tarafın kapalı olduğunu varsaydığında, bu durum ağ bölünmesi (partition) olarak tanımlanır. Yani, kesinti tespit edildiğinde, node'lar birbirlerinden bağımsız olarak çalışmaya başlar.

## Log Girdileri, HTTP API ve CLI İle Tespit Yöntemleri

- **Log Girdileri:**  
  Ağ bölünmesi durumu, RabbitMQ log dosyalarına otomatik olarak kaydedilir. Loglarda "inconsistent_database" veya "running_partitioned_network" gibi hata mesajları yer alır. Bu mesajlar, hangi node'ların birbirleriyle iletişim kuramadığını gösterir.
- **HTTP API:**  
  Yönetim HTTP API’si kullanılarak, GET `/api/nodes` sorgusu yapılabilir. Bu API çağrısı sonucunda, her node için "partitions" bilgileri alınır; böylece ağda bir bölümleme (partition) olup olmadığı hızlıca anlaşılır.
- **CLI Komutları:**  
  `rabbitmq-diagnostics cluster_status` veya `rabbitmqctl cluster_status` komutları çalıştırıldığında, ağ bölünmesi bilgileri çıktı olarak sunulur. Ağ bölünmesi yoksa genellikle "Network Partitions" kısmı boş görünür; ancak bir bölünme var ise, iletişim kurulamadığı belirtilen node'lar listelenir.

# Ağ Bölünmesi Sırasında Davranış

Ağ bölünmesi gerçekleştiğinde, cluster içerisindeki düğümler arasında iletişim kesintisi meydana gelir ve cluster iki veya daha fazla bağımsız bölüme ayrılır. Bu durum şu önemli etkileri beraberinde getirir:

- **Bölünme (Split-Brain) Durumunun Oluşumu ve Etkileri:**

  - Ağ bölünmesi sırasında, farklı alt bölümler (partition) birbirlerini tamamen "çökmüş" olarak algılar. Her bölüm, diğer bölümün çalışmadığını düşünerek kendi başına işlem yapmaya başlar.
  - Bu senaryo "split-brain" olarak adlandırılır; iki veya daha fazla bölüm birbirleriyle senkronize olmadan bağımsız olarak gelişim gösterir.
  - Sonuç olarak, aynı cluster içinde veri tutarlılığı ve küme durumu açısından çelişkili sonuçlar ortaya çıkabilir.

- **Bölünmenin Kuyruklar, Binding’ler ve Exchange’ler Üzerindeki Etkisi:**
  - Ağ bölünmesi esnasında, her bir alt bölüm üzerinde kuyruklar, binding’ler ve exchange’ler bağımsız olarak oluşturulabilir ya da silinebilir.
  - Örneğin, quorum kuyruklar durumu göz önüne alındığında, çoğunlukta bulunan bölüm yeni bir lider seçecektir.
  - Azınlıkta kalan bölümdeki quorum kuyruk replikaları, yeni mesaj kabul etme ve tüketicilere mesaj iletme gibi işlemler gerçekleştiremez; bu işlemler yalnızca çoğunluk bölümündeki lider tarafından yürütülür.
  - Ağ kesintisi sona erse bile, uygun bir bölünme müdahale stratejisi (örneğin, pause_minority) yapılandırılmamışsa, split-brain durumu devam edebilir.

# Askıya Alma ve Devam Ettirme Nedeniyle Oluşan Bölünmeler

Bu bölümde, işletim sistemi veya sanal makine askıya alma (suspend) ve devam ettirme (resume) işlemleri sonucu ortaya çıkan ağ bölünmeleri incelenmektedir. Bu durum, düğümlerin çökmediği ancak iletişimlerinin kesildiği senaryolarda meydana gelir:

- **OS veya Sanal Makine Askıya Alınması:**

  - Bir cluster düğümü, işletim sistemi veya sanal makinenin askıya alınması durumunda kendi kendine kapanmadığını düşünür.
  - Ancak, diğer düğümler askıya alınmış olan düğümü "çalışmıyor" olarak algılar ve bu durum cluster içindeki iletişimin kesilmesine neden olur.
  - Örneğin, bir sanal makine hipervizör tarafından askıya alındığında, düğüm aktif görünse de cluster’ın geri kalanı onu erişilemez sayabilir.

- **Asimetrik Bölünmelerin Oluşum Özellikleri:**
  - Askıya alma nedeniyle oluşan bölünmeler genellikle asimetriktir; askıya alınan düğüm kendini çalışır durumda görürken, diğer düğümler tarafından devre dışı kabul edilir.
  - Bu asimetrik algı, cluster’ın bazı bölümlerinde tutarsız duruma yol açabilir. Örneğin, askıya alınmış düğüm normal çalışmaya devam ederken, diğer düğümler onun yokluğunda farklı kurtarma veya bölünme stratejileri uygulayabilir.
  - Bu durum özellikle pause_minority gibi bölünme yönetim stratejileri için önemli sonuçlar doğurur, çünkü asimetrik bölümlemede hangi düğümlerin aktif sayılacağı konusunda belirsizlik yaşanabilir.

Sonuç olarak, sanal makine veya işletim sisteminin askıya alınması sonucu meydana gelen bölünmelerde, iletişim kesintileri ve asimetrik davranışlar nedeniyle cluster tutarlılığı ve yönetimi ekstra dikkat gerektirir.

# Split-Brain Durumundan Kurtulma

Split-brain durumu, cluster içerisindeki farklı bölümlerdeki nodların birbirlerinden izole şekilde çalışması sonucunda sistem durumunda tutarsızlıklar meydana getirebilir. Bu durumu düzeltmek için aşağıdaki adımlar izlenir:

## 1. Güvenilir Bölümün Seçilmesi

- **Güvenilir Bölümün Belirlenmesi:**  
  Split-brain durumundan kurtulmak için ilk olarak cluster'da ortaya çıkan bölümlerden hangisinin en güvenilir ve en güncel veri ile sistem durumuna (schema, mesajlar) sahip olduğuna karar verilmelidir. Seçilen bu bölüm, cluster’ın tek yetkili kaynağı haline gelir; diğer bölümlerde yapılan değişiklikler bu seçime göre iptal edilir.

## 2. Kurtarma Adımları ve Durumu Sıfırlama Yöntemleri

- **Diğer Bölümlerdeki Nodların Yeniden Başlatılması:**  
  Güvenilir bölüm dışında kalan tüm nodlar, önce tamamen durdurulmalı ardından yeniden başlatılmalıdır. Yeniden başlatılan bu nodlar, cluster’a katıldıklarında güvenilir bölümden durumu (schema, mesajlar) alarak kendilerini yeniden senkronize eder.
- **Güvenilir Bölümdeki Nodların Yeniden Başlatılması:**  
  Son olarak, cluster uyarısını temizlemek ve tutarlılığı sağlamak amacıyla, güvenilir olarak belirlenen bölümdeki nodların da yeniden başlatılması önerilir. Bu adım, sistemin tek ve uyumlu bir cluster halinde çalışmaya devam etmesini sağlar.

# Bölünme Yönetimi Stratejileri

RabbitMQ, ağ bölünmeleri (network partitions) durumuyla otomatik olarak başa çıkmak için çeşitli stratejiler sunar. Bu stratejiler, bölünme anında hangi düğümlerin askıya alınacağı, hangilerinin çalışma durumunu koruyacağı veya hangi düğümlerin otomatik olarak yeniden başlatılacağına karar vermede kullanılır. Aşağıda, kullanılan ana stratejiler ile konfigürasyon detayları ve kıyaslamaları yer almaktadır:

## 1. Pause-minority Modu

- **Özellikleri:**
  - Ağ bölünmesi başladığında, cluster içerisindeki düğümlerden toplam düğüm sayısının yarısı veya daha azına sahip olan taraf (azınlık) otomatik olarak askıya alınır.
  - Böylece split-brain (çifte beyin) durumunun oluşması engellenir.
  - Bölünme sona erdiğinde askıya alınan düğümler yeniden başlatılır ve cluster, güvenilir kısmın verisiyle senkronize edilir.
- **Konfigürasyon:**

```erlang
cluster_partition_handling = pause_minority
```

- **Avantajları ve Dezavantajları:**
  - Avantaj: Küçük partideki düğümlerin askıya alınması sayesinde veri tutarlılığı korunur ve split-brain senaryosu önlenir.
  - Dezavantaj: Ağ bölünmesi sırasında azınlıkta kalan düğümler hizmet vermediği için geçici erişim kaybı yaşanabilir.

## 2. Pause-if-all-down Modu

- **Özellikleri:**
  - Bu modda, konfigürasyon dosyasında listelenen belirli düğümlerden hiçbiri ulaşılabilir olmadığında, diğer düğümler otomatik olarak askıya alınır.
  - Yöneticilere, hangi düğümlerin kritik olduğunu belirleyip tercih sırasını netleştirme imkanı tanır.
  - Listelenen düğümlerin iki tarafa da dağılmış olması durumunda, ek olarak ignore veya autoheal seçeneği ile kurtarma stratejisi devreye girer.
- **Konfigürasyon:**

```erlang
cluster_partition_handling = pause_if_all_down

## Recovery strategy. Can be either 'autoheal' or 'ignore'
cluster_partition_handling.pause_if_all_down.recover = ignore

## Node names to check
cluster_partition_handling.pause_if_all_down.nodes.1 = rabbit@myhost1
cluster_partition_handling.pause_if_all_down.nodes.2 = rabbit@myhost2
```

- **Avantajları ve Dezavantajları:**
  - Avantaj: Yöneticiler hangi düğümlerin kritik olduğunu belirleyerek sadece bu düğümlere dayalı bir kontrol sağlayabilir; böylece bölünme durumunda istenmeyen düğümlerin otomatik askıya alınması sağlanabilir.
  - Dezavantaj: Listede yer alan düğümlerin iki farklı parçaya da dağılması durumunda ek ayarlamalar yapmak gerekeceğinden yapılandırma biraz karmaşıklaşabilir.

## 3. Autoheal Modu

- **Özellikleri:**
  - Ağ bölünmesi sona erdiğinde, RabbitMQ otomatik olarak “kazanan” bölmeyi belirler. Bu bölüm en fazla istemciye bağlı veya en çok düğüm barındıran taraf olarak seçilir.
  - Kazanmayan düğümler yeniden başlatılır ve kazanan bölümden senkronize edilir.
  - Bu mod, bölünme başladığında değil, sona erdiğinde etkili olarak çalışır.
- **Konfigürasyon:**

```erlang
cluster_partition_handling = autoheal
```
- **Avantajları ve Dezavantajları:**
    - Avantaj: Bölünme sona erdiğinde otomatik olarak en güvenilir bölümün belirlenip, diğer düğümlerin yeniden senkronize edilerek cluster'ın güncel duruma ulaşması sağlanır.
    - Dezavantaj: Veri tutarlılığı üzerindeki riskler ve istemci hizmet sürekliliği açısından dikkatli yapılandırılması gerekir.

## Varsayılan Mod: Ignore
* Varsayılan davranış olarak herhangi bir müdahale yapılmaz; ağ bölünmesi oluşsa bile RabbitMQ düğümleri otomatik olarak askıya alınmaz.
* Bu mod, yüksek ağ güvenilirliği sağlanabildiği durumlar için tercih edilir ancak split-brain riskini beraberinde getirir.
Seçilecek strateji; cluster ortamının ağ güvenilirliği, veri tutarlılığı gereksinimleri ve hizmet sürekliliği gibi faktörlere bağlı olarak belirlenir. Her mod, farklı senaryolara hitap ettiği için sistem yöneticisinin ihtiyaçlarına en uygun olanın seçilmesi önem taşır.


# Hangi Modun Seçileceği

RabbitMQ'nun otomatik ağ bölünmesi (network partition) durumlarında uygulayabileceği modlar; sistemin aktifliği, veri tutarlılığı ve ağ güvenilirliği arasında bir denge kurmayı amaçlar. Aşağıda, her modun avantajları ve dezavantajları ile operatörün tercih yapabilmesi için kılavuz yer almaktadır:

- **Ignore Modu:**
    - **Avantajları:**
        - Ağ bağlantılarının en yüksek güvenilirlikte olduğu durumlarda tüm düğümlerin aktif kalması sağlanır.
        - Düğüm kullanılabilirliği en üst düzeyde tutulmak istendiğinde tercih edilir.
    - **Dezavantajları:**
        - Ağ bölünmesi meydana geldiğinde, split-brain senaryosuna yol açarak veri tutarlılığında sorunlar yaşanabilir.
        - Çoğunluk ilkesine dayalı senkronizasyon sağlanmadığından, farklı bölümler arasında tutarsızlık riski artar.

- **Pause-Minority Modu:**
    - **Avantajları:**
        - Bölünme sırasında, toplam düğüm sayısının yarısından azını oluşturan azınlık grubundaki düğümler otomatik olarak askıya alınır.
        - Böylece, split-brain durumunun oluşması engellenir ve veri tutarlılığı korunur.
        - Özellikle düğümlerin farklı raflarda veya kullanılabilirlik bölgelerinde yer aldığı senaryolarda; çoğunlukta kalan düğümlerin güvenilirliği esas alınır.
    - **Dezavantajları:**
        - Bölünme anında azınlıkta kalan düğümlerin hizmet dışı kalması, geçici erişim kaybına neden olabilir.
        - İki düğümlü ortamlarda kullanıldığında, her iki düğüm de askıya alınabileceğinden önerilmez.

- **Autoheal Modu:**
    - **Avantajları:**
        - Ağ bölünmesi sona erdiğinde otomatik olarak “kazanan” (güvenilir) bölümü belirler ve diğer düğümleri yeniden başlatarak uyumlu bir cluster oluşturur.
        - Operatör müdahalesine gerek kalmadan sistemde otomatik onarım sağlanır.
    - **Dezavantajları:**
        - Bölünme esnasında veri tutarlılığı üzerinde risk oluşturabilir; çünkü senkronizasyon tamamlanmadan yapılacak işlemlerde uyumsuzluklar meydana gelebilir.
        - Hizmet kesintileri sonrasında otomatik onarımın gerçekleştirilmesi, bazı durumlarda veri senkronizasyon sorunlarına yol açabilir.

### Operatör Tercih Kılavuzu

- **Ağ Güvenilirliği Çok Yüksekse:**
    - Tüm düğümler aynı raf veya aynı switch aracılığıyla kesintisiz bağlantıya sahipse, **ignore** modu tercih edilebilir. Bu durumda, mevcut ağ yapısı düğüm kullanılabilirliğini maksimum düzeyde korur.

- **Farklı Fiziksel Konumlarda ya da Kullanılabilirlik Bölgelerinde Çalışılıyorsa:**
    - Düğümlerin birbirinden farklı yerlerde konumlandığı veya ağ bağlantılarının kesilme olasılığının (veya bölünme durumlarında azınlık oluşmasının) düşük olduğu senaryolarda, **pause-minority** modu idealdir. Bu mod, split-brain oluşumunu engelleyerek veri tutarlılığını sağlar.

- **Hizmet Sürekliliği Öncelikli ve Sistem Otomasyonu İstenen Durumlarda:**
    - Veri tutarlılığı ile esneklik arasında denge kurmak istiyorsanız ve hizmet kesintilerini en aza indirgemek öncelikliyse, **autoheal** modu tercih edilebilir. Bu modda, ağ bölünmesinin ardından sistem otomatik olarak kendini onarır.

Operatörün, cluster'ın dağıtım ortamı, kullanıcı erişimi, veri tutarlılığı gereksinimleri ve ağ yapılandırmasına göre bu modlar arasında ideal dengeyi seçmesi, sistemin verimli ve güvenilir çalışması açısından kritik öneme sahiptir.