# Ne işe yarar?

İki sunucuda dosya yedekliliğini sağlayan GlusterFS'in kurulumunu ve yapılandırmasını otomatik olarak yapar.

# Ne içerir?

- `ssh_key_setup_functions.sh`: Sunucular arasında şifresiz ssh bağlantı kurulabilmesi için gerekli olan ssh-key oluşturur. Tek bir fonksiyon çalıştığında her iki sunucu için de karşılıklı anahtarları oluşturur ve herkese açık anahtarları sunucular arasında değiş tokuş yapar.

- `ssh_key_setup.sh`: `ssh_key_setup_functions.sh` dosyasındaki fonksiyonlar yardımıyla sunucular arasında şifresiz ssh bağlantısının altyapısını oluşturur.

- `yardimci_scriptler.sh`: Bu klasördeki scriptlerin çalışmasını test etme işini hızlandırmak için yazılmış scriptler bulunur. GlusterFS'i tamamen kaldırmak gibi.

- `glusterfs_setup.sh`: GlusterFS'in kurulumunu ve yapılandırmasını otomatik olarak yapmak için yazılmış fonksiyonları içerir.

- `create_glusterFS_functions.sh`: `glusterfs_setup.sh` dosyasındaki fonksiyonları kullanarak kurulumu hem yerelde hem de uzak sunucuda yapan fonksiyonları içerir.

- `create_glusterFS.sh`: `create_glusterFS_functions.sh` dosyasındaki fonksiyonları kullanarak GlusterFS'in kurulumunu ve yapılandırmasını hem yerelde hem de uzak sunucuda otomatik olarak yapar. Bu scripti çalıştırmadan önce `ssh_key_setup.sh` scriptini çalıştırmanız gerekmektedir. (şifresiz şekilde ssh bağlantısı oluşturabilmek için)
- `set_node_variables.sh`: GlusterFS'in kurulumu ve yapılandırmasının hangi sunucuda yapıldığına göre ip ve kullanıcı atama işlemlerini yapar.

# Örnek Kullanım

Şifresiz SSH bağlantısı kurmak için script:
```bash
./ssh_key_setup.sh --is-node1 false --node1-ip 10.207.80.10 --node1-user vboxuser --node2-ip 10.207.80.11 --node2-user vboxuser
```

GlusterFS'i kurmak ve yapılandırmak için script:
```bash
./create_glusterFS.sh --is-node1 false --node1-ip 10.207.80.10 --node2-ip 10.207.80.11
```