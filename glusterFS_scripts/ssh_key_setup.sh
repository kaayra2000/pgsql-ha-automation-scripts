
#!/bin/bash

# Scriptin bulunduğu dizini alma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/ssh_key_setup_functions.sh
source $SCRIPT_DIR/../argument_parser.sh
source $SCRIPT_DIR/../general_functions.sh

parse_and_read_arguments "$@"

setup_ssh_keys