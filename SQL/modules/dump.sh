#!/bin/bash
# dump.sh - Dump e exportação de dados sensíveis

dump_sqlmap_results() {
    local outdir="$1"
    local dumpdir="$2"
    mkdir -p "$dumpdir"
    find "$outdir" -name '*.csv' -exec cp {} "$dumpdir" \;
}
