#!bin/bash
#Primeiro código em shell script/bash
echo "Digite o nome da interface de rede (ex: eth0, wlan0): "
read interface
echo "Detalhes da interface $interface exibidos abaixo:"
ifconfig $interface




