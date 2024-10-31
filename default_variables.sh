#!/bin/bash
# ha-proxy değişkenleri
DEFAULT_NODE1_IP="10.207.80.21"
DEFAULT_NODE2_IP="10.207.80.22"
DEFAULT_ETCD_IP="10.207.80.23"
DEFAULT_HAPROXY_BIND_PORT="7000"
DEFAULT_PGSQL_PORT="5432"
DEFAULT_HAPROXY_PORT="8008"

# keepalived değişkenleri
DEFAULT_INTERFACE="enp0s3"
DEFAULT_SQL_VIRTUAL_IP="10.207.80.20"
DEFAULT_DNS_VIRTUAL_IP="10.207.80.30"
DEFAULT_PRIORITY="100"
DEFAULT_STATE="BACKUP"
DEFAULT_SQL_CONTAINER="sql_container"
DEFAULT_DNS_CONTAINER="dns_container"
DOCKER_BINARY_PATH="/usr/bin/docker"

# Docker değişkenleri
SHELL_PATH_IN_DOCKER="/usr/local/bin"

VARSAYILAN_ARAYUZ="enp0s3"
VARSAYILAN_NETMASK="23"
VARSAYILAN_GATEWAY="10.40.30.1"
VARSAYILAN_DNS="10.251.0.21"
ETCD_PORT_0=2379
ETCD_PORT_1=2380
REPLIKATOR_KULLANICI_ADI="replicator"
POSTGRES_SIFRESI="123qwe"
REPLICATOR_SIFRESI="123qwe"
