#!/bin/bash

find . -type f -not -path "*/\.*" -exec sh -c 'echo "=== DOSYA YOLU: \"{}\" ===\n"; cat "{}"; echo "\n"' \; > output.txt