#!/bin/bash
    #Script que mostra um laço de repetição utilizando 'for'

for i in {100..0}
do
    sleep 1
    echo "Número $i"
done
echo "Contagem regressiva finalizada!"