# Keepalived Kurulum ve Yapılandırma Scriptleri - README

## Dosyalar ve İşlevleri

### 1. create_keepalived.sh

- Ana kontrol scripti
- Diğer tüm scriptleri import eder
- Sırasıyla tüm kurulum adımlarını çalıştırır
- Keepalived kurulumunu ve yapılandırmasını yönetir

### 2. argument_parser.sh

- Parametre işleme scripti
- Varsayılan değerleri tanımlar:
  - DEFAULT_INTERFACE="enp0s3"
  - DEFAULT_SQL_VIRTUAL_IP="10.207.80.20"
  - DEFAULT_DNS_VIRTUAL_IP="10.207.80.30"
  - DEFAULT_PRIORITY="100"
  - DEFAULT_STATE="BACKUP"
  - DEFAULT_SQL_CONTAINER="sql_container"
  - DEFAULT_DNS_CONTAINER="dns_container"
- Komut satırı parametrelerini işler

### 3. container_scripts.sh

- Konteyner kontrol scripti
- Docker konteynerlerinin durumunu kontrol eden scriptleri oluşturur
- Konteyner durum kontrollerini loglar

### 4. keepalived_setup.sh

- Keepalived kurulum ve yapılandırma scripti
- Keepalived paketini kurar
- Keepalived yapılandırma dosyasını oluşturur
- Servisi başlatır ve etkinleştirir

### 5. logging.sh

- Loglama yönetim scripti
- Log dosyalarını oluşturur
- Log dosyası izinlerini ayarlar
- Log dosyası sahipliklerini yapılandırır

### 6. user_management.sh

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
_--dns-container :\* DNS konteyner adı (Varsayılan: dns_container)

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
