import requests

EMAILS = []

for i in range(36):
    response = requests.get(f"	http://98.81.71.8/rest/products/{i}/reviews")

    data_json = response.json()

    for review in data_json["data"]:
        email = review["author"]

        if email not in EMAILS:
            EMAILS.append(email)
            print(email)
