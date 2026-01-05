#!/bin/bash
    #Script pra demonstrar argumentos passados na chamada do script:
 if ["$1" == "R"]
 then
 echo "Mostrando rotas"
 elif ["$1" == "i"]
 then
 Echo "Mostrando interfaces de rede $2"
 ifconfig $2
 else
 echo "usage: argumento.sh R|i eth0"
 fi