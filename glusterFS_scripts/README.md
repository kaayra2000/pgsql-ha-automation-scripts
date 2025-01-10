# Ne işe yarar?

İki sunucuda dosya yedekliliğini sağlayan GlusterFS'in kurulumunu ve yapılandırmasını otomatik olarak yapar.

# Ne içerir?

- `ssh_key_setup_functions.sh`: Sunucular arasında şifresiz ssh bağlantı kurulabilmesi için gerekli olan ssh-key oluşturur. Tek bir fonksiyon çalıştığında her iki sunucu için de karşılıklı anahtarları oluşturur ve herkese açık anahtarları sunucular arasında değiş tokuş yapar.

- `ssh_key_setup`: `ssh_key_setup_functions.sh` dosyasındaki fonksiyonlar yardımıyla sunucular arasında şifresiz ssh bağlantısının altyapısını oluşturur.