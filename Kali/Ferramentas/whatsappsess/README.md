# WhatsappSess (by Ziron)
## PoC for educational purposes showing how it is possible to use phishing to gain access to whatsapp
LEGAL NOTICE AND DISCLAIMER
THIS PROJECT IS ONLY A PROOF OF CONCEPT (PoC) FOR EDUCATIONAL AND DIGITAL SECURITY AWARENESS PURPOSES.

🚨 USE PROHIBITED FOR MALICIOUS ACTIVITIES:
This software was developed exclusively for cybersecurity education.
Using it to attack systems without explicit authorization is a CRIME.
You are solely responsible for any misuse of this tool.
The author is not responsible for any illegal actions performed by third parties.

### Instalation

#### Windows
First install python then run
```bash
# Usar PowerShell como Administrador
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```
#### Linux
```bash
# Instalar pacotes do sistema primeiro
sudo apt update
sudo apt install python3-pip python3-venv firefox-geckodriver

# Depois usar ambiente virtual (método recomendado)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Usage
```bash
python whatsappsess.py
```