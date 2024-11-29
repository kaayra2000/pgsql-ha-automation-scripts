# Ne işe yarar?

Bu dosyaların amacı ubuntu üzerinde otomatik keepalived kurulabilmesine vesile olmaktır.

# Ne içerir?

- `create_keepalived.sh`: Bir üst dizindeki `arguments.cfg` dosyasındaki değişkenleri ve `keepalived_setup.sh` dosyasındaki fonksiyonları kullanarak keepalived kurulumunu yapar.
- `keepalived_setup.sh`: keepalived konfigürasyonunu oluşturmak ve keepalived'yi başlatmak için kullanılan çeşitli fonksiyonları içerir.
- `container_scripts.sh`: İlgili konteynerler ayakta mı kontrolü için script oluşturmaya yarar. Eğer ilgili konteyner ayakta değilse, ve diğer keepalivedlardan birisinde bu konteyner ayaktaysa ilgili ip'yi diğer keepalived'e devreder.
- logging.sh: Log dosyası oluşturma komutlarını içerir.
- user_management.sh: keepalived_script kullanıcısını oluşturur ve docker grup izinlerini ayarlar.

# Nasıl kullanılır?

Normal şartlarda `docker_scripts/docker_sql.sh` dosyası bu dosyaları kullanarak keepalived kurulumunu yapar. Ancak bu dosyaları tek başına çalıştırmak isterseniz aşağıdaki komutu çalıştırabilirsiniz.

```bash
./create_keepalived.sh
```

Eğer hangi argümanları alabildiğini öğrenmek istiyorsanız aşağıdaki komutları çalıştırabilirsiniz.

```bash
./create_keepalived.sh -h
```
```bash
./create_keepalived.sh --help
```

Örnek bir kullanım:

```bash
./create_keepalived.sh --keepalived-interface enp0s3 \
--sql-virtual-ip 10.207.80.20 --dns-virtual-ip 10.207.80.30 \
--keepalived-priority 100 --keepalived-state BACKUP \
--sql-container-name sql_container --dns-container-name dns_container
```

**Önemli**: interface bulunamazsa sistem başlamaz.

# Not

- Eğer argümanları teker teker geçirmek istemiyorsanız `arguments.cfg` dosyasını düzenleyerek `create_keepalived.sh` dosyasını çalıştırabilirsiniz. Zaten varsayılan olarak oradaki değerler alınacaktır.

- Eğer argümanları yukarıdaki örnekteki gibi geçirirseniz `create_keepalived.sh` dosyası `arguments.cfg` dosyasındaki değerleri değiştirecektir. Bu durumda, ilk geçirdiğiniz değerleri tekrar geçirmek istiyorsanız, bir daha argümanaları yukarıdaki örnekteki gibi geçirmenize gerek yoktur.

- `arguments.cfg` dosyasında bu `create_keepalived.sh` dosyasında kullanılmayan argümanlar da bulunmaktadır. Tüm ***komut*** (.sh) dosyalarının argümanları tek bir merkezde toplandığı için bu durum normaldir. Eğer sadece `create_keepalived.sh` komut dosyasını çalıştıracaksanız `arguments.cfg` dosyasındaki fazlalık argümanları umursamayın.

