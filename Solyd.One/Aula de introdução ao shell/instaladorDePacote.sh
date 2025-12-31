#!/bin/bash
echo " Digite o nome do pacote que deseja instalar: "
read pacote 
echo " Instalando o pacote $pacote ..."
apt install $pacote -y
echo "Pacote $pacote instalado com sucesso!"
apt list -a $pacote