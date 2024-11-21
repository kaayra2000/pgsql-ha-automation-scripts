#!/bin/bash
# Script'in bulunduğu dizini alma
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/default_variables.sh"
source "$ROOT_DIR/general_functions.sh"
ARGUMENT_CFG_FILE="$ROOT_DIR/arguments.cfg"

# Argümanları işleyen genel fonksiyon
parse_all_arguments() {
    # Define your arguments in an array
    declare -a ARGUMENTS=(
        # Key                   Command-line Argument       Default Value                      Help Description
        # HAProxy Arguments
        "NODE1_IP"              "--node1-ip"                "$DEFAULT_NODE1_IP"                "IP address of Node 1"
        "NODE2_IP"              "--node2-ip"                "$DEFAULT_NODE2_IP"                "IP address of Node 2"
        "HAPROXY_BIND_PORT"     "--haproxy-bind-port"       "$DEFAULT_HAPROXY_BIND_PORT"       "HAProxy bind port"
        "PGSQL_PORT"            "--pgsql-port"              "$DEFAULT_PGSQL_PORT"              "PostgreSQL port"
        "HAPROXY_PORT"          "--haproxy-port"            "$DEFAULT_HAPROXY_PORT"            "HAProxy port"
        "POSTGRES_BIND_PORT"    "--postgres-bind-port"      "$DEFAULT_POSTGRES_BIND_PORT"      "PostgreSQL bind port"

        # Keepalived Arguments
        "INTERFACE"             "--interface"               "$DEFAULT_INTERFACE"               "Network interface"
        "SQL_VIRTUAL_IP"        "--sql-virtual-ip"          "$DEFAULT_SQL_VIRTUAL_IP"          "SQL virtual IP address"
        "DNS_VIRTUAL_IP"        "--dns-virtual-ip"          "$DEFAULT_DNS_VIRTUAL_IP"          "DNS virtual IP address"
        "PRIORITY"              "--priority"                "$DEFAULT_PRIORITY"                "Priority for Keepalived"
        "STATE"                 "--state"                   "$DEFAULT_STATE"                   "Initial state (MASTER/BACKUP)"
        "SQL_CONTAINER"         "--sql-container"           "$DEFAULT_SQL_CONTAINER"           "SQL container name"
        "DNS_CONTAINER"         "--dns-container"           "$DEFAULT_DNS_CONTAINER"           "DNS container name"

        # Patroni Arguments
        "NODE_NAME"             "--node-name"               "$DEFAULT_NODE_NAME"               "Name of the node"
        "ETCD_IP"               "--etcd-ip"                 "$DEFAULT_ETCD_IP"                 "ETCD IP address"
        "REPLIKATOR_KULLANICI_ADI" "--replicator-username"  "$DEFAULT_REPLIKATOR_KULLANICI_ADI" "Replicator username"
        "REPLICATOR_SIFRESI"    "--replicator-password"     "$DEFAULT_REPLICATOR_SIFRESI"      "Replicator password"
        "POSTGRES_SIFRESI"      "--postgres-password"       "$DEFAULT_POSTGRES_SIFRESI"        "Postgres password"
        "IS_NODE_1"             "--is-node1"                "$DEFAULT_IS_NODE_1"               "Is this Node 1?"

        # ETCD Arguments
        "ETCD_CLIENT_PORT"      "--client-port"             "$DEFAULT_ETCD_CLIENT_PORT"        "ETCD client port"
        "ETCD_PEER_PORT"        "--peer-port"               "$DEFAULT_ETCD_PEER_PORT"          "ETCD peer port"
        "CLUSTER_TOKEN"         "--cluster-token"           "$DEFAULT_CLUSTER_TOKEN"           "Cluster token"
        "CLUSTER_STATE"         "--cluster-state"           "$DEFAULT_CLUSTER_STATE"           "Cluster state (new/existing)"
        "ETCD_NAME"             "--etcd-name"               "$DEFAULT_ETCD_NAME"               "Name of the ETCD node"
        "ELECTION_TIMEOUT"      "--election-timeout"        "$DEFAULT_ELECTION_TIMEOUT"        "Election timeout"
        "HEARTBEAT_INTERVAL"    "--heartbeat-interval"      "$DEFAULT_HEARTBEAT_INTERVAL"      "Heartbeat interval"
        "DATA_DIR"              "--data-dir"                "$DEFAULT_DATA_DIR"                "Data directory"
    )
    # Initialize configuration associative array with default values
    declare -A config
    local arg_count=${#ARGUMENTS[@]}
    for ((i=0; i<$arg_count; i+=4)); do
        local key="${ARGUMENTS[i]}"
        local default_value="${ARGUMENTS[i+2]}"
        config["$key"]="$default_value"
    done

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_argument_help "$0" ARGUMENTS
                exit 0
                ;;
            *)
                local found=false
                for ((i=0; i<$arg_count; i+=4)); do
                    local key="${ARGUMENTS[i]}"
                    local flag="${ARGUMENTS[i+1]}"
                    if [ "$1" == "$flag" ]; then
                        config["$key"]="$2"
                        shift 2
                        found=true
                        break
                    fi
                done
                if ! $found; then
                    echo "Uyarı: Bilinmeyen argüman '$1' atlanıyor"
                    shift 1
                fi
                ;;
        esac
    done

    # Write variables to the config file
    > "$ARGUMENT_CFG_FILE"  # Clear or create the file
    for key in "${!config[@]}"; do
        echo "$key=${config[$key]}" >> "$ARGUMENT_CFG_FILE"
    done
}