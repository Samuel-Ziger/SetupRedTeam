#!usr/bin/pyhton3
# Estruturas Condicionais

import sys

if len(sys.argv) >= 3:
    if sys.argv[1].isdigit() and sys.argv[2].isdigit() and sys.argv[1] != "0" and sys.argv[2] != "0":
        primeiro_numero = int(sys.argv[1])
        segundo_numero = int(sys.argv[2])

        print("A soma é: ", primeiro_numero + segundo_numero)
        print("A subtração é: ", primeiro_numero - segundo_numero)
    else: 
        print("Os valores precisam ser númericos e diferentes de zero ")
else:
    print(" Passe como argumento dois numeros")