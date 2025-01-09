# Ne işe yarar?

İki sunucuda dosya yedekliliğini sağlayan GlusterFS'in kurulumunu ve yapılandırmasını otomatik olarak yapar.

# Ne içerir?

- `generate_glusterDS_ssh_key.sh`: Sunucular arasında şifresiz ssh bağlantı kurulabilmesi için gerekli olan ssh-key oluşturur. Tek bir fonksiyon çalıştığında her iki sunucu için de karşılıklı anahtarları oluşturur ve herkese açık anahtarları sunucular arasında değiş tokuş yapar.