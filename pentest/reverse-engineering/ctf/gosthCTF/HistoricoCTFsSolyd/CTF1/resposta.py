import socket
import time
from PIL import Image, ImageOps
from pyzbar import pyzbar

ip = "98.92.173.139"
port = 5000

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((ip, port))

print(s.recv(1024).decode())
s.send(b"ok")

while True:
    time.sleep(0.5)

    data = s.recv(100000).decode()
    data = data.replace(" ", "").split(";")

    size = len(data)
    qrcode = Image.new("RGB", (size, size))

    data.pop()

    for i in range(len(data)):
        data[i] = data[i].split(",(")

        for j in range(len(data[i])):
            pixel = tuple(
                map(int, data[i][j].replace("(", "").replace(")", "").split(","))
            )
            qrcode.putpixel((i, j), pixel)

    # adicionar borda branca (quiet zone) para melhorar leitura
    qrcode = ImageOps.expand(qrcode, border=10, fill="white")

    decoded = pyzbar.decode(qrcode)

    if decoded:
        resposta = decoded[0].data
        print("QR Decodificado:", resposta)
        s.send(resposta)
