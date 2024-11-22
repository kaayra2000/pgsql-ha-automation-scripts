# Keepalived Kurulum ve Yapılandırma Scriptleri - README

## Dosyalar ve İşlevleri

### create_keepalived.sh

- Ana kontrol scripti
- Diğer tüm scriptleri import eder
- Sırasıyla tüm kurulum adımlarını çalıştırır
- Keepalived kurulumunu ve yapılandırmasını yönetir

### container_scripts.sh

- Konteyner kontrol scripti
- Docker konteynerlerinin durumunu kontrol eden scriptleri oluşturur
- Konteyner durum kontrollerini loglar

### keepalived_setup.sh

- Keepalived kurulum ve yapılandırma scripti
- Keepalived paketini kurar
- Keepalived yapılandırma dosyasını oluşturur
- Servisi başlatır ve etkinleştirir

### logging.sh

- Loglama yönetim scripti
- Log dosyalarını oluşturur
- Log dosyası izinlerini ayarlar
- Log dosyası sahipliklerini yapılandırır

### user_management.sh

- Kullanıcı yönetim scripti
- keepalived_script kullanıcısını oluşturur
- Docker grup izinlerini ayarlar
- Sudo yetkilerini yapılandırır

## Kullanım

./create_keepalived.sh [PARAMETRELER]

Parametreler:
_--interface :_ Ağ arayüzü (Varsayılan: enp0s3)
_--sql-virtual-ip :_ SQL sanal IP adresi (Varsayılan: 10.207.80.20)
_--dns-virtual-ip :_ DNS sanal IP adresi (Varsayılan: 10.207.80.30)
_--priority :_ Öncelik değeri (Varsayılan: 100)
_--state : Durum (MASTER/BACKUP) (Varsayılan: BACKUP)
_--sql-container :_ SQL konteyner adı (Varsayılan: sql_container)
_--dns-container :_ DNS konteyner adı (Varsayılan: dns_container)

## Örnek Kullanım

```bash
./create_keepalived.sh \
 --interface eth0 \
 --sql-virtual-ip 192.168.1.100 \
 --dns-virtual-ip 192.168.1.101 \
 --priority 100 \
 --state MASTER \
 --sql-container sql_1 \
 --dns-container dns_1
```
Dikkat: interface bulunamazsa sistem başlamaz.

## Sistem Gereksinimleri

- Linux işletim sistemi
- Sudo yetkileri
- Docker kurulumu
- İnternet bağlantısı (paket kurulumu için)

## Notlar

- Script sudo yetkisi gerektirir
- Docker kurulu olmalıdır
- Konteynerler önceden oluşturulmuş olmalıdır
- Log dosyaları /var/log/ dizininde oluşturulur
