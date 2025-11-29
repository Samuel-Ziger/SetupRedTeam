#!/bin/bash
# log.sh - Logging e auditoria profissional

log_jsonl() {
    # Uso: log_jsonl NÍVEL MENSAGEM
    local level="$1"; shift
    local msg="$*"
    local ts=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    local ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    local host=$(hostname)
    local hash_maquina=$(hostname | sha256sum | awk '{print $1}')
    echo -n '{'
    echo -n '"timestamp":"'$ts'",'
    echo -n '"level":"'$level'",'
    echo -n '"host":"'$host'",'
    echo -n '"ip":"'$ip'",'
    echo -n '"machine_hash":"'$hash_maquina'",'
    echo -n '"message":'$(jq -Rs . <<< "$msg")
    echo '}'
}

log_file_jsonl() {
    # Uso: log_file_jsonl NÍVEL MENSAGEM ARQUIVO
    local level="$1"; shift
    local msg="$1"; shift
    local file="$1"
    log_jsonl "$level" "$msg" >> "$file"
}

log_hash_file() {
    # Uso: log_hash_file ARQUIVO
    local file="$1"
    if [ -f "$file" ]; then
        sha256sum "$file" | awk '{print $1}'
    fi
}
