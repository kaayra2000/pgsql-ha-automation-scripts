#!/bin/bash

set_swarm_node_variables() {
    if [ "$IS_NODE_1" = "true" ]; then
        CURRENT_NODE_IP="$NODE1_IP"
    else
        CURRENT_NODE_IP="$NODE2_IP"
    fi
}