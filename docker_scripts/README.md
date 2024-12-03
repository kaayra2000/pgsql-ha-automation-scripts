# Ne işe yarar?

Bu dosyalar yüksek erişilebilirlik sağlamak amacıyla docker üzerinde otomatik olarak veri tabanı ve dns sunucusu kurulabilmesine vesile olmaktadır.

# Ne içerir?

- `create_image.sh`: Docker image oluşturmak için kullanılan komut dosyasıdır.
- `docker_dns.sh`: `docker_files/docker_dns` docker dosyasını temel alır ve `create_dns_server.sh` dosyasını çalıştırarak bir dns sunucusu oluşturur.
- `docker_sql.sh`: `docker_files/docker_sql` docker dosyasını temel alır ve `etcd_scripts/create_etcd.sh`, `haproxy_scripts/create_haproxy.sh` ve `keepalived_scripts/create_keepalived.sh`, `patroni_scripts/create_patroni.sh` dosyalarını çalıştırarak bir veri tabanı sunucusu oluşturur.

# Nasıl kullanılır?

- `docker_dns.sh` dosyasını çalıştırmak için aşağıdaki komutu çalıştırabilirsiniz.

    ```bash
    ./docker_dns.sh
    ```

    Eğer hangi argümanları alabildiğini öğrenmek istiyorsanız aşağıdaki komutları çalıştırabilirsiniz.

    ```bash
    ./docker_dns.sh -h
    ```
    ```bash
    ./docker_dns.sh --help
    ```

    Örnek bir kullanım:

    ```bash
    ./docker_dns.sh --dns-port 53 \
    --dns-docker-forward-port 7777
    ```

- `docker_sql.sh` dosyasını çalıştırmak için aşağıdaki komutu çalıştırabilirsiniz.

    ```bash
    ./docker_sql.sh
    ```

    Eğer hangi argümanları alabildiğini öğrenmek istiyorsanız aşağıdaki komutları çalıştırabilirsiniz.

    ```bash
    ./docker_sql.sh -h
    ```
    ```bash
    ./docker_sql.sh --help
    ```

    Örnek bir kullanım:

    ```bash
    ./docker_sql.sh --node1-ip 10.207.80.10 --node2-ip 10.207.80.11 \
    --haproxy-bind-port 7000 --pgsql-port 5432 --haproxy-port 8008 \
    --pgsql-bind-port 5000 --etcd-client-port 2379 --etcd-peer-port 2380 \
    --etcd-cluster-token cluster1 --etcd-cluster-state new --etcd-name etcd1 \
    --etcd-election-timeout 5000 --etcd-heartbeat-interval 1000 \
    --etcd-data-dir /var/lib/etcd/default \
    --node1-ip 10.207.80.10 --node2-ip 10.207.80.11 --haproxy-bind-port 7000 \
    --pgsql-port 5432 --haproxy-port 8008 --pgsql-bind-port 5000
    ```

# Not

- Eğer argümanları teker teker geçirmek istemiyorsanız `arguments.cfg` dosyasını düzenleyerek her iki dosyayı da çalıştırabilirsiniz. Zaten varsayılan olarak oradaki değerler alınacaktır.

- Eğer argümanları yukarıdaki örneklerdeki gibi geçirirseniz komut dosyaları `arguments.cfg` dosyasındaki değerleri değiştirecektir. Bu durumda, ilk geçirdiğiniz değerleri tekrar geçirmek istiyorsanız, bir daha argümanaları yukarıdaki örnekteki gibi geçirmenize gerek yoktur.

- `arguments.cfg` dosyasında her iki komut dosyasında da kullanılmayan argümanlar da bulunmaktadır. Tüm ***komut*** (.sh) dosyalarının argümanları tek bir merkezde toplandığı için bu durum normaldir. Eğer sadece bir komut dosyasını çalıştıracaksanız `arguments.cfg` dosyasındaki fazlalık argümanları umursamayın.