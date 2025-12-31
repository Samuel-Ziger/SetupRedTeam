#!/bin/bash
# sqlmap.sh - Funções para execução e parsing profissional do SQLMap

run_sqlmap_json() {
    # Uso: run_sqlmap_json URL TECNICA EXTRA_OPCOES OUTPUT_DIR
    local url="$1"; shift
    local technique="$1"; shift
    local extra_opts="$1"; shift
    local outdir="$1"; shift
    sqlmap -u "$url" --technique="$technique" $extra_opts --batch --output-dir="$outdir" --output-format=json
}

parse_sqlmap_json() {
    # Uso: parse_sqlmap_json ARQUIVO_JSON
    local file="$1"
    if [ -f "$file" ]; then
        jq '.' "$file"
    fi
}
