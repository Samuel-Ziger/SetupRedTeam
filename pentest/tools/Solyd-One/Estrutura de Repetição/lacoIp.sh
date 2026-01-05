#!/bin/bash
    # Script de laço de repetição com IPs

for i in $(cat ip.txt)
do
    echo "$i"
done
