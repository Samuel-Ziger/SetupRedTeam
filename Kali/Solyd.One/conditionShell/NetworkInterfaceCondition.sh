#!/bin/bash
#script de condição para rotas ou interfaces de rede

echo " Digite (R) para rotas ou (I) para interfaces de rede: "
read entrada
if [ "$entrada" == "R"]
then
echo "Mostrando rotas de rede:"
route -n
elif   [ "$entrada" == "I"]
then

echo "Digite o nome da interface de rede (ex: eth0, wlan0): "
read interface
echo "Detalhes da interface $interface exibidos abaixo:"
ifconfig $interface
else
echo "Entrada inválida. Por favor, digite R ou I."
fi



