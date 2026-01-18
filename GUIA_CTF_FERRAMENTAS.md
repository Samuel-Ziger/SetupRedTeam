# 🎯 Guia Completo de Ferramentas para CTF - SetupRedTeam

**Baseado na auditoria completa do repositório**  
**Criado em: Janeiro 2026**

---

## 📋 SUMÁRIO

Este guia lista as ferramentas mais úteis do repositório **SetupRedTeam** para CTF, priorizadas e categorizadas por tipo de desafio.

---

## 🔥 TIER 1 - FERRAMENTAS ESSENCIAIS (USE SEMPRE)

### 1. 🔐 Quebra de Hashes e Ciphers

#### `pentest/credentials/hashes/ciphey/` ⭐⭐⭐⭐⭐
**PRIORIDADE: CRÍTICA**
- **O que faz:** Quebra automática de ciphers e encodings
- **Quando usar:** QUALQUER desafio de crypto que não exija conhecimento específico
- **Uso:** `ciphey "texto_criptografado"`
- **Vantagem:** Tenta múltiplos algoritmos automaticamente
- **Exemplos de uso CTF:**
  ```bash
  # Quebra base64, hex, rot13, etc automaticamente
  ciphey "U29tZSBjcnlwdG8gdGV4dA=="
  
  # De arquivo
  ciphey -f encrypted.txt
  ```
- **Status:** ✅ Ferramenta moderna e ativa
- **Recomendação:** ⭐⭐⭐⭐⭐ **PRIMEIRA FERRAMENTA a tentar em crypto**

#### `pentest/credentials/hashes/name-that-hash/` ⭐⭐⭐⭐⭐
**PRIORIDADE: CRÍTICA**
- **O que faz:** Identifica o tipo de hash antes de quebrar
- **Quando usar:** SEMPRE que encontrar um hash
- **Uso:** `nth "hash_aqui"` ou `name-that-hash "hash"`
- **Vantagem:** Economiza tempo - já sabe qual ferramenta usar
- **Exemplos de uso CTF:**
  ```bash
  # Identificar tipo de hash
  name-that-hash "5d41402abc4b2a76b9719d911017c592"
  
  # Depois use hashcat ou john conforme identificado
  hashcat -m 0 hash.txt wordlist.txt  # MD5
  ```
- **Status:** ✅ Ferramenta moderna
- **Recomendação:** ⭐⭐⭐⭐⭐ **SEMPRE identifique o hash primeiro**

#### `pentest/credentials/hashes/search-that-hash/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA**
- **O que faz:** Busca hash em databases online (rainbow tables)
- **Quando usar:** Hashes comuns que já foram quebrados
- **Uso:** `sth "hash_aqui"`
- **Vantagem:** Quebra instantânea se já foi quebrado antes
- **Exemplos de uso CTF:**
  ```bash
  search-that-hash "5d41402abc4b2a76b9719d911017c592"
  ```
- **Status:** ✅ Ferramenta ativa
- **Recomendação:** ⭐⭐⭐⭐ Tente antes de brute force

---

### 2. 🔍 Identificação de Dados

#### `pentest/credentials/hashes/pywhat/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA**
- **O que faz:** Identifica tipo de dado (base64, hex, URL, email, etc)
- **Quando usar:** Quando encontrar uma string misteriosa
- **Uso:** `pywhat "string_aqui"`
- **Vantagem:** Diz exatamente o que você encontrou
- **Exemplos de uso CTF:**
  ```bash
  pywhat "ZmxhZ3t0aGlzX2lzX2FfZmxhZ30="
  # Identifica: base64, flag, etc
  ```
- **Status:** ✅ Ferramenta moderna
- **Recomendação:** ⭐⭐⭐⭐ Útil para steganography e misc

---

### 3. 🏴 Reverse Engineering

#### `pentest/reverse-engineering/frameworks/pwntools/` ⭐⭐⭐⭐⭐
**PRIORIDADE: CRÍTICA PARA REVERSING/BINARY**
- **O que faz:** Framework Python para exploit development
- **Quando usar:** DESAFIOS DE BINARY, REVERSING, PWN
- **Uso:** Scripts Python usando pwntools
- **Vantagem:** Padrão da indústria para exploit dev
- **Exemplos de uso CTF:**
  ```python
  from pwn import *
  
  # Conectar a serviço remoto
  r = remote('ctf.example.com', 1337)
  
  # Enviar payload
  payload = b'A' * 64 + p64(0x401234)
  r.sendline(payload)
  
  # Receber flag
  flag = r.recvall()
  print(flag)
  ```
- **Status:** ✅ Framework padrão da indústria
- **Recomendação:** ⭐⭐⭐⭐⭐ **ESSENCIAL para binary/pwn challenges**

#### `pentest/reverse-engineering/ctf/katana/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA PARA CTF**
- **O que faz:** CTF automation tool
- **Quando usar:** Automação de CTF challenges
- **Uso:** Depende da ferramenta específica (várias no diretório)
- **Status:** ✅ Ferramentas CTF
- **Recomendação:** ⭐⭐⭐⭐ Específico para CTF

#### `pentest/reverse-engineering/debuggers/dnspy/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA PARA .NET**
- **O que faz:** Debugger e editor de assemblies .NET
- **Quando usar:** Desafios .NET, executáveis C#
- **Uso:** Abrir arquivo .exe ou .dll no dnSpy
- **Status:** ✅ Ferramenta profissional
- **Recomendação:** ⭐⭐⭐⭐ **MELHOR ferramenta para .NET reversing**

---

### 4. 📚 Wordlists

#### `wordlists/` ⭐⭐⭐⭐⭐
**PRIORIDADE: CRÍTICA**
- **O que contém:** 283 wordlists profissionais
- **Quando usar:** SEMPRE em brute force, fuzzing, directory discovery
- **Wordlists essenciais para CTF:**
  ```
  wordlists/discovery/
    ├── common.txt           # Diretórios comuns
    ├── directory_list_*.txt # Listas de diretórios
    ├── lfi_*.txt           # Local File Inclusion
    └── sensitive_files_*.txt # Arquivos sensíveis
  
  wordlists/passwords/
    ├── common_passwords_*.txt
    ├── xato_net_passwords.txt
    └── default_passwords_for_services.txt
  
  wordlists/usernames/
    └── usernames/*.txt
  
  wordlists/vulnerabilities/
    └── vulnerabilities/*.txt # Padrões de vulnerabilidades
  ```
- **Recomendação:** ⭐⭐⭐⭐⭐ **SEMPRE use wordlists do repositório**

---

## 🔶 TIER 2 - FERRAMENTAS MUITO ÚTEIS

### 5. 🌐 Web Challenges

#### `pentest/exploitation/web/generic/Arjun/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA PARA WEB**
- **O que faz:** Descobre parâmetros HTTP ocultos
- **Quando usar:** Web challenges com parâmetros escondidos
- **Uso:** `arjun -u http://target.com/page -w wordlist.txt`
- **Recomendação:** ⭐⭐⭐⭐ Muito útil para web challenges

#### `pentest/exploitation/web/generic/wfuzz/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA PARA WEB**
- **O que faz:** Fuzzing avançado de web
- **Quando usar:** Directory discovery, parameter fuzzing
- **Uso:**
  ```bash
  # Fuzzing de diretórios
  wfuzz -w wordlists/discovery/common.txt http://target.com/FUZZ
  
  # Fuzzing de parâmetros
  wfuzz -w wordlists/vulnerabilities/*.txt http://target.com/page?FUZZ=test
  ```
- **Recomendação:** ⭐⭐⭐⭐ Clássico e confiável

#### `pentest/exploitation/web/generic/domdig/` ⭐⭐⭐
**PRIORIDADE: MÉDIA PARA WEB**
- **O que faz:** Scanner de DOM XSS
- **Quando usar:** Web challenges focados em XSS
- **Uso:** `domdig http://target.com`
- **Recomendação:** ⭐⭐⭐ Específico para XSS challenges

#### `pentest/exploitation/web/generic/tplmap/` ⭐⭐⭐
**PRIORIDADE: MÉDIA PARA WEB**
- **O que faz:** Template injection exploitation
- **Quando usar:** SSTI (Server-Side Template Injection) challenges
- **Uso:** `python tplmap.py -u http://target.com/page?name=test`
- **Recomendação:** ⭐⭐⭐ Específico para SSTI

---

### 6. 🔷 GraphQL Challenges

#### `pentest/exploitation/web/graphql/clairvoyance/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA PARA GRAPHQL**
- **O que faz:** Extrai schema GraphQL mesmo sem introspection
- **Quando usar:** GraphQL challenges com introspection desabilitada
- **Uso:** `clairvoyance https://target.com/graphql -o schema.json`
- **Recomendação:** ⭐⭐⭐⭐ **MELHOR ferramenta para GraphQL sem introspection**

#### `pentest/exploitation/web/graphql/inql/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA PARA GRAPHQL**
- **O que faz:** Burp extension + CLI para teste GraphQL
- **Quando usar:** GraphQL challenges em geral
- **Uso:** `inql -t https://target.com/graphql`
- **Recomendação:** ⭐⭐⭐⭐ Complementa clairvoyance

---

### 7. 📱 Mobile Challenges

#### `pentest/mobile-security/android/apkleaks/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA PARA ANDROID**
- **O que faz:** Encontra URIs, endpoints e secrets em APKs
- **Quando usar:** Android CTF challenges
- **Uso:** `apkleaks -f challenge.apk`
- **Recomendação:** ⭐⭐⭐⭐ Essencial para mobile challenges

#### `pentest/mobile-security/android/andriller/` ⭐⭐⭐
**PRIORIDADE: MÉDIA PARA ANDROID**
- **O que faz:** Android forensics
- **Quando usar:** Mobile forensics challenges
- **Recomendação:** ⭐⭐⭐ Específico para forensics

---

### 8. 🔐 Credentials/Passwords

#### `pentest/credentials/brute-force/crowbar/` ⭐⭐⭐
**PRIORIDADE: MÉDIA**
- **O que faz:** Brute force para RDP, SSH, VNC, VPN
- **Quando usar:** Network challenges que requerem brute force de credenciais
- **Uso:** `crowbar -b rdp -s 192.168.1.100 -U users.txt -C passwords.txt`
- **Recomendação:** ⭐⭐⭐ Útil para network challenges

---

## 🔹 TIER 3 - FERRAMENTAS ESPECÍFICAS (USE QUANDO NECESSÁRIO)

### 9. 🔍 Enumeração e Discovery

#### `pentest/exploitation/web/generic/buster/` ⭐⭐⭐
**PRIORIDADE: MÉDIA**
- **O que faz:** Brute force inteligente de diretórios/arquivos
- **Quando usar:** Web challenges que precisam de directory discovery avançado
- **Recomendação:** ⭐⭐⭐ Alternativa ao Gobuster/Dirb

#### `pentest/exploitation/web/generic/PadBuster/` ⭐⭐⭐
**PRIORIDADE: BAIXA (ESPECÍFICO)**
- **O que faz:** Padding Oracle attacks
- **Quando usar:** Crypto challenges com padding oracle vulnerability
- **Uso:** `perl padBuster.pl http://target.com/encrypt?data=TEST plaintext ciphertext block_size`
- **Recomendação:** ⭐⭐⭐ Muito específico, mas indispensável quando precisar

---

### 10. 📋 Referências Rápidas

#### `docs/references/cheatsheets/` ⭐⭐⭐⭐
**PRIORIDADE: ALTA (CONSULTA RÁPIDA)**
- **O que contém:** 279 cheatsheets profissionais
- **Quando usar:** SEMPRE que precisar de sintaxe rápida
- **Cheatsheets úteis para CTF:**
  - `nmap` - Port scanning
  - `gdb` - Debugging
  - `sqlmap` - SQL injection
  - `curl` - HTTP requests
  - `awk`, `sed` - Text processing
  - `python` - Python quick reference
  - `bash` - Shell scripting
- **Recomendação:** ⭐⭐⭐⭐ **IMPRESCINDÍVEL para consulta rápida**

---

## 🎯 WORKFLOW RECOMENDADO POR TIPO DE CHALLENGE

### 🔐 CRYPTO Challenges

**Passo 1:** Identifique o tipo
```bash
pywhat "dado_misterioso"
name-that-hash "hash_se_tiver"
```

**Passo 2:** Quebra automática
```bash
ciphey "texto_criptografado"
# ou
ciphey -f arquivo_criptografado.txt
```

**Passo 3:** Se falhar, tente buscar online
```bash
search-that-hash "hash_aqui"
```

**Passo 4:** Manual com ferramentas específicas (openssl, john, hashcat)

---

### 🌐 WEB Challenges

**Passo 1:** Enumeração básica
```bash
# Directory discovery
wfuzz -w wordlists/discovery/common.txt http://target.com/FUZZ

# Parameter discovery
arjun -u http://target.com/page
```

**Passo 2:** Análise específica
- **XSS:** `domdig http://target.com`
- **SSTI:** `tplmap -u http://target.com/page?name=test`
- **GraphQL:** `clairvoyance http://target.com/graphql`

**Passo 3:** Exploração manual (Burp, navegador, scripts)

---

### 🏴 BINARY/PWN Challenges

**Passo 1:** Análise estática
```bash
file binary
strings binary
# Se .NET: dnSpy
```

**Passo 2:** Análise dinâmica
```bash
gdb ./binary
# Use cheatsheets/gdb para comandos
```

**Passo 3:** Exploit com pwntools
```python
from pwn import *
# Desenvolva exploit no pwntools
```

---

### 📱 MOBILE Challenges

**Passo 1:** Extrair informações
```bash
apkleaks -f challenge.apk
```

**Passo 2:** Análise de código
- Decompilar APK (apktool, jadx)
- Analisar código extraído

**Passo 3:** Teste dinâmico (emulador ou dispositivo)

---

### 🔍 MISC/Steganography Challenges

**Passo 1:** Identificação
```bash
file arquivo_misterioso
pywhat "string_encontrada"
```

**Passo 2:** Análise de arquivos
- `strings arquivo` - Texto oculto
- `binwalk` - Arquivos embutidos
- `steghide`, `stegsolve` - Esteganografia
- `foremost`, `binwalk -e` - Extração

**Passo 3:** Decodificação
```bash
ciphey "texto_extraído"
```

---

## 📦 FERRAMENTAS EXTERNAS COMPLEMENTARES (NÃO NO REPO)

Essas não estão no repositório, mas são ESSENCIAIS para CTF:

1. **Binwalk** - Análise de firmware/binários
2. **Steghide/Stegsolve** - Esteganografia
3. **John the Ripper** - Quebra de hashes
4. **Hashcat** - Quebra de hashes (GPU)
5. **Burp Suite** - Web proxy
6. **Ghidra** - Reverse engineering
7. **IDA Free** - Reverse engineering
8. **CyberChef** - Ferramenta web para encoding/decoding
9. **Dcode.fr** - Decodificador online
10. **RsaCtfTool** - RSA challenges

---

## 🎓 ESTRATÉGIA GERAL PARA CTF

### Ordem de Ataque Recomendada:

1. **Sempre comece com:** `ciphey`, `pywhat`, `name-that-hash`
   - Muitas vezes resolve automaticamente
   - Economiza tempo valioso

2. **Se falhar, consulte:** `docs/references/cheatsheets/`
   - Sintaxe rápida
   - Comandos essenciais

3. **Use wordlists do repo:** `wordlists/`
   - Já testadas e organizadas
   - Economiza tempo de busca

4. **Para challenges específicos:**
   - **Web:** Arjun → wfuzz → domdig/tplmap
   - **Crypto:** ciphey → search-that-hash → manual
   - **Binary:** dnSpy (se .NET) → gdb → pwntools
   - **Mobile:** apkleaks → análise manual

5. **Não se esqueça:** Pwntools para binary/pwn
   - Framework mais usado em CTF
   - Economiza tempo de coding

---

## ✅ CHECKLIST RÁPIDO DE FERRAMENTAS

Antes do CTF, verifique se tem instalado:

- ✅ **ciphey** - `pip install ciphey`
- ✅ **name-that-hash** - `pip install name-that-hash`
- ✅ **pywhat** - `pip install pywhat`
- ✅ **pwntools** - `pip install pwntools`
- ✅ **arjun** - `pip install arjun`
- ✅ **wfuzz** - `apt install wfuzz` ou `pip install wfuzz`
- ✅ **wordlists/** - Já estão no repo
- ✅ **cheatsheets/** - Já estão no repo

---

## 📝 NOTAS FINAIS

### Prioridades Absolutas para CTF:

1. **ciphey** - Quebra 80% dos challenges crypto simples
2. **name-that-hash** - Economiza tempo identificando hashes
3. **pwntools** - ESSENCIAL para binary/pwn
4. **wordlists/** - Base para brute force e fuzzing
5. **cheatsheets/** - Referência rápida constante

### Dicas:

- ⚡ Use `ciphey` PRIMEIRO em qualquer string misteriosa
- ⚡ Consulte `cheatsheets/` SEMPRE que precisar de sintaxe
- ⚡ Use wordlists do repo - já são testadas
- ⚡ Pwntools é seu melhor amigo em binary/pwn
- ⚡ Não reinvente a roda - use as ferramentas do repo

---

## 🚀 COMANDOS RÁPIDOS PARA COPIAR/COLAR

```bash
# Crypto - quebra automática
ciphey "string_misteriosa"
ciphey -f arquivo.txt

# Hash - identificar tipo
name-that-hash "hash_aqui"

# Web - descobrir parâmetros
arjun -u http://target.com/page

# Web - fuzzing diretórios
wfuzz -w wordlists/discovery/common.txt http://target.com/FUZZ

# GraphQL - extrair schema
clairvoyance http://target.com/graphql -o schema.json

# Mobile - analisar APK
apkleaks -f challenge.apk

# Python - pwntools template básico
python3 -c "from pwn import *; r = remote('host', 1337); r.interactive()"
```

---

**Fim do Guia**

*Atualizado em: Janeiro 2026*  
*Baseado na auditoria completa do SetupRedTeam*

