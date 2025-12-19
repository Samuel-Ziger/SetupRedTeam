#!/bin/bash
# Script para realizar varredura de portas em um alvo especificado

for i in {0..254}
do 
    ping -c 1 "$1.$i" | grep ttl | cut -d " " -f 4 | sed 's/.$//' &
done

echo "Varredura concluída."
