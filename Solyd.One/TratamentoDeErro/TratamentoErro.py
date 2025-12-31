#!usr/bin/pyhton3
# Tratamento de erro

import sys
def somar (numero1, numero2):
    return numero1 + numero2

def dividir (numero1, numero2):
    try:
        resultado = numero1 / numero2
    except ZeroDivisionError:
        return "Não é possível dividir por zero"
    return resultado

if len(sys.argv) >= 3:
    if sys.argv[1].isdigit() and sys.argv[2].isdigit() :
        primeiro_numero = int(sys.argv[1])
        segundo_numero = int(sys.argv[2])

        print("A soma é: ", somar(primeiro_numero, segundo_numero))
        print("A subtração é: ", dividir(primeiro_numero, segundo_numero))
    else: 
        print("Os valores precisam ser númericos ")
else:
    print(" Passe como argumento dois numeros")