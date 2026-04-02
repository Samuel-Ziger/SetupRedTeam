import socket
import re

ip = "3.222.207.113"
port = 50123
soma = 0

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((ip, port))

data = s.recv(1024).decode()

numberlist = re.findall(r"\d+", data)

print(numberlist)

for numero in numberlist:
    soma += int(numero)

s.send(str(soma).encode())

print(s.recv(1024).decode())
