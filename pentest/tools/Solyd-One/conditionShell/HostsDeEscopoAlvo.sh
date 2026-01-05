#!/bin/bash
 #script para verificar hosts de escopo alvo e passar valor:

echo " Qauntos host existem no arquivo de escopo alvo? "
read number

if (( number >= 0 && number <= 20)); then 
    echo " Valor final  do penset será de : R$ 36.000 "
elif (( number > 20 && number <= 60)); then
    echo " Valor final do penset será de : R$ 50.000"
elif (( number > 60 && number <= 100)); then
    echo " Valor final do penset será de : R$ 100.000"
else
    echo " Conslutar com a equipe comercial o valor customizado do penset "

fi
