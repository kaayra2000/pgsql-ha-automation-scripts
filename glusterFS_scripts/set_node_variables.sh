#!/bin/bash

# NODE1 kontrolünü yapan fonksiyon
set_node_variables() {
    if [ "$IS_NODE_1" = "true" ]; then
        remote_ip="$NODE2_IP"
        remote_user="$NODE2_USER"
        local_ip="$NODE1_IP"
        local_user="$NODE1_USER"
    else
        remote_ip="$NODE1_IP"
        remote_user="$NODE1_USER"
        local_ip="$NODE2_IP"
        local_user="$NODE2_USER"
    fi
}