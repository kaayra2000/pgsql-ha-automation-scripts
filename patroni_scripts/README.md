# Ne işe yarar?

Bu dosyaların amacı docker üzerinde otomatik patroni kurulabilmesine vesile olmaktır. `docker_scripts/docker_sql.sh` dosyası bu klasördeki dosyaları kullanır.

# Ne içerir?

- `create_patroni.sh`: Bir üst dizindeki `arguments.cfg` dosyasındaki değişkenleri ve `patroni_setup.sh` dosyasındaki fonksiyonları kullanarak patroni kurulumunu yapar.
- `patroni_setup.sh`: patroni konfigürasyonunu oluşturmak ve patroni'yi başlatmak için kullanılan çeşitli fonksiyonları içerir.

# Nasıl kullanılır?

Normal şartlarda `docker_scripts/docker_sql.sh` dosyası bu dosyaları kullanarak patroni kurulumunu yapar. Ancak bu dosyaları tek başına çalıştırmak isterseniz aşağıdaki komutu çalıştırabilirsiniz.

```bash
./create_patroni.sh
```

Eğer hangi argümanları alabildiğini öğrenmek istiyorsanız aşağıdaki komutları çalıştırabilirsiniz.

```bash
./create_patroni.sh -h
```
```bash
./create_patroni.sh --help
```

Örnek bir kullanım:

```bash
./create_patroni.sh --patroni-node-name pg_node1 \
--etcd-virtual-ip 10.207.80.22 --etcd-client-port 2379 --replicator-username replicator \
--replicator-password replicator_pass --postgres-password postgres_pass \
--pgsql-port 5432 --is-node1 true --node1-ip 10.207.80.10 \
--node2-ip 10.207.80.11 --haproxy-port 8008 
```

# Not

- Eğer argümanları teker teker geçirmek istemiyorsanız `arguments.cfg` dosyasını düzenleyerek `create_patroni.sh` dosyasını çalıştırabilirsiniz. Zaten varsayılan olarak oradaki değerler alınacaktır.

- Eğer argümanları yukarıdaki örnekteki gibi geçirirseniz `create_patroni.sh` dosyası `arguments.cfg` dosyasındaki değerleri değiştirecektir. Bu durumda, ilk geçirdiğiniz değerleri tekrar geçirmek istiyorsanız, bir daha argümanaları yukarıdaki örnekteki gibi geçirmenize gerek yoktur.

- `arguments.cfg` dosyasında bu `create_patroni.sh` dosyasında kullanılmayan argümanlar da bulunmaktadır. Tüm ***komut*** (.sh) dosyalarının argümanları tek bir merkezde toplandığı için bu durum normaldir. Eğer sadece `create_patroni.sh` komut dosyasını çalıştıracaksanız `arguments.cfg` dosyasındaki fazlalık argümanları umursamayın.