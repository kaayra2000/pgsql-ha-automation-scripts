# Ne işe yarar?

Bu dosyaların amacı docker üzerinde otomatik haproxy kurulabilmesine vesile olmaktır. `docker_scripts/docker_sql.sh` dosyası bu klasördeki dosyaları kullanır.

# Ne içerir?

- `create_haproxy.sh`: Bir üst dizindeki `arguments.cfg` dosyasındaki değişkenleri ve `haproxy_setup.sh` dosyasındaki fonksiyonları kullanarak haproxy kurulumunu yapar.
- `haproxy_setup.sh`: haproxy konfigürasyonunu oluşturmak ve haproxy'yi başlatmak için kullanılan çeşitli fonksiyonları içerir.

# Nasıl kullanılır?

Normal şartlarda `docker_scripts/docker_sql.sh` dosyası bu dosyaları kullanarak haproxy kurulumunu yapar. Ancak bu dosyaları tek başına çalıştırmak isterseniz aşağıdaki komutu çalıştırabilirsiniz.

```bash
./create_haproxy.sh
```

Eğer hangi argümanları alabildiğini öğrenmek istiyorsanız aşağıdaki komutları çalıştırabilirsiniz.

```bash
./create_haproxy.sh -h
```
```bash
./create_haproxy.sh --help
```

Örnek bir kullanım:

```bash
./create_haproxy.sh --node1-ip 10.207.80.10 --node2-ip 10.207.80.11 \
--haproxy-bind-port 7000 --pgsql-port 5432 --haproxy-port 8008 --pgsql-bind-port 5000
```

# Not

- Eğer argümanları teker teker geçirmek istemiyorsanız `arguments.cfg` dosyasını düzenleyerek `create_haproxy.sh` dosyasını çalıştırabilirsiniz. Zaten varsayılan olarak oradaki değerler alınacaktır.

- Eğer argümanları yukarıdaki örnekteki gibi geçirirseniz `create_haproxy.sh` dosyası `arguments.cfg` dosyasındaki değerleri değiştirecektir. Bu durumda, ilk geçirdiğiniz değerleri tekrar geçirmek istiyorsanız, bir daha argümanaları yukarıdaki örnekteki gibi geçirmenize gerek yoktur.

- `arguments.cfg` dosyasında bu `create_haproxy.sh` dosyasında kullanılmayan argümanlar da bulunmaktadır. Tüm ***komut*** (.sh) dosyalarının argümanları tek bir merkezde toplandığı için bu durum normaldir. Eğer sadece `create_haproxy.sh` komut dosyasını çalıştıracaksanız `arguments.cfg` dosyasındaki fazlalık argümanları umursamayın.