# Ne işe yarar?

Bu dosyalar yüksek erişilebilirlik sağlamak amacıyla otomatik olarak veri tabanı ve dns sunucusu kurma işleminin docker üzerinde olmasına vesile olmaktadır.

# Ne içerir?

- `docker_dns`: `docker_scripts/docker_dns.sh` komut dosyasının temel aldığı docker dosyasıdır.
- `docker_sql`: `docker_scripts/docker_sql.sh` komut dosyasının temel aldığı docker dosyasıdır.

# Not

Bilhassa yeni komut dosyası ekleme ya da bir komut dosyasında yeni bir komut dosyası içe aktarma işlemlerinde, eklenen ya da bu içe aktarılan dosyanın bu dosyalarada `COPY` komutuyla içe aktarılmasını unutmamak gerekir. 

## Örnek Kullanım

```dockerfile
# Yeni bir script dosyası ekleme
COPY create_dns_server.sh /usr/local/bin/

# Başka bir dosyayı içe aktarma
COPY argument_parser.sh /usr/local/bin/
```

**Önemli Hatırlatma**:
* Docker container içinde çalışacak tüm dosyalar COPY komutu ile kopyalanmalıdır.
* Bu adım atlanırsa, dosyalar container içinde erişilemez olacaktır.
* Uygulamanın düzgün çalışması için bu adım önemlidir.