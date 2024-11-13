# postgres-ha-infrastructure

Bu depo temel olarak PostgreSQL'in yüksek erişilebilirlik mimarisini ve dns sunucusunun yine yüksek erişilebilirlik mimarisini shell scriptler ile otomatik olarak oluşturmayı hedeflemektedir. İçerisinde haproxy, etcd, patroni, keepalived, postgresql ve bind9 servislerini barındırmaktadır. Bu servislerin bir kısmı docker konteynırlarında çalıştırılmaktadır.

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