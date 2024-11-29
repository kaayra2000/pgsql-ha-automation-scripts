# Ne işe yarar?

Bu dosyaların amacı docker üzerinde otomatik etcd kurulabilmesine vesile olmaktır. `docker_scripts/docker_sql.sh` dosyası bu klasördeki dosyaları kullanır.

# Ne içerir?

- `create_etcd.sh`: Bir üst dizindeki `arguments.cfg` dosyasındaki değişkenleri ve `etcd_setup.sh` dosyasındaki fonksiyonları kullanarak etcd kurulumunu yapar.
- `etcd_setup.sh`: etcd konfigürasyonunu oluşturmak ve etcd'yi başlatmak için kullanılan çeşitli fonksiyonları içerir.

# Nasıl kullanılır?

Normal şartlarda `docker_scripts/docker_sql.sh` dosyası bu dosyaları kullanarak etcd kurulumunu yapar. Ancak bu dosyaları tek başına çalıştırmak isterseniz aşağıdaki komutu çalıştırabilirsiniz.

```bash
./create_etcd.sh
```

Eğer hangi argümanları alabildiğini öğrenmek istiyorsanız aşağıdaki komutları çalıştırabilirsiniz.

```bash
./create_etcd.sh -h
```
```bash
./create_etcd.sh --help
```

Örnek bir kullanım:

```bash
./create_etcd.sh --etcd-client-port 2379 -etcd-peer-port 2380 \
--etcd-cluster-token cluster1 --etcd-cluster-state new --etcd-name etcd1 \
--etcd-election-timeout 5000 --etcd-heartbeat-interval 1000 \
--etcd-data-dir /var/lib/etcd/default
```

# Not

- Eğer argümanları teker teker geçirmek istemiyorsanız `arguments.cfg` dosyasını düzenleyerek `create_etcd.sh` dosyasını çalıştırabilirsiniz. Zaten varsayılan olarak oradaki değerler alınacaktır.

- Eğer argümanları yukarıdaki örnekteki gibi geçirirseniz `create_etcd.sh` dosyası `arguments.cfg` dosyasındaki değerleri değiştirecektir. Bu durumda, ilk geçirdiğiniz değerleri tekrar geçirmek istiyorsanız, bir daha argümanaları yukarıdaki örnekteki gibi geçirmenize gerek yoktur.

- `arguments.cfg` dosyasında bu `create_etcd.sh` dosyasında kullanılmayan argümanlar da bulunmaktadır. Tüm ***komut*** (.sh) dosyalarının argümanları tek bir merkezde toplandığı için bu durum normaldir. Eğer sadece `create_etcd.sh` komut dosyasını çalıştıracaksanız `arguments.cfg` dosyasındaki fazlalık argümanları umursamayın.