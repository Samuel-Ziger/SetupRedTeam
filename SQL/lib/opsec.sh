#!/bin/bash
# opsec.sh - Funções de OPSEC e coleta de auditoria

get_operator_ip() {
    curl -s --max-time 5 https://ifconfig.me || echo "N/A"
}

get_machine_hash() {
    (hostname; uname -a; cat /etc/machine-id 2>/dev/null) | sha256sum | awk '{print $1}'
}
