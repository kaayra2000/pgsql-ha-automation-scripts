#!/bin/bash
# ha-proxy değişkenleri
DEFAULT_NODE1_IP="10.207.80.10"
DEFAULT_NODE2_IP="10.207.80.11"
DEFAULT_HAPROXY_BIND_PORT="7000"
DEFAULT_HAPROXY_PORT="8008"

# PostgreSQL ve Patroni değişkenleri
DEFAULT_PATRONI_NODE1_NAME="pg_node1"
DEFAULT_PATRONI_NODE2_NAME="pg_node2"
DEFAULT_PGSQL_PORT="5432"
DEFAULT_PGSQL_BIND_PORT="5000"
DEFAULT_REPLIKATOR_KULLANICI_ADI="replicator"
DEFAULT_REPLICATOR_SIFRESI="111"
DEFAULT_POSTGRES_SIFRESI="111"
DEFAULT_IS_NODE_1="true"
DEFAULT_PATRONI_ADMIN_USER="admin"
DEFAULT_PATRONI_ADMIN_PASSWORD="admin"

# keepalived değişkenleri
DEFAULT_KEEPALIVED_INTERFACE="enp0s3"
DEFAULT_SQL_VIRTUAL_IP="10.207.80.20"
DEFAULT_DNS_VIRTUAL_IP="10.207.80.30"
DEFAULT_KEEPALIVED_PRIORITY="100"
DEFAULT_KEEPALIVED_STATE="BACKUP"
DEFAULT_SQL_CONTAINER_NAME="sql_container"
DEFAULT_DNS_CONTAINER_NAME="dns_container"

# ETCD varsayılan değerleri
DEFAULT_ETCD_IP=$DEFAULT_SQL_VIRTUAL_IP
DEFAULT_ETCD_CLIENT_PORT="2379"
DEFAULT_ETCD_PEER_PORT="2380"
DEFAULT_ETCD_CLUSTER_TOKEN="cluster1"
DEFAULT_ETCD_CLUSTER_KEEPALIVED_STATE="new"
DEFAULT_ETCD_NAME="etcd1"
DEFAULT_ETCD_ELECTION_TIMEOUT="5000"
DEFAULT_ETCD_HEARTBEAT_INTERVAL="1000"
DEFAULT_ETCD_DATA_DIR="/var/lib/etcd/default"

# Docker değişkenleri
SHELL_PATH_IN_DOCKER="/usr/local/bin"

# DNS Argümanları
DEFAULT_DNS_PORT="53"
DEFAULT_DNS_DOCKER_FORWARD_PORT="7777"