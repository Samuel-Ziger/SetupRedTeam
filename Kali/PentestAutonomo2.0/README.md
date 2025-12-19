# Scripts de Exploração Autônoma

Este diretório contém scripts autônomos e agressivos de exploração de segurança para uso em testes de penetração autorizados.

## ⚠️ AVISO LEGAL

**ESTES SCRIPTS SÃO PARA USO APENAS EM AMBIENTES AUTORIZADOS E PARA FINS DE TESTE DE PENETRAÇÃO LEGAL. O uso não autorizado é ilegal e pode resultar em consequências criminais.**

## 📋 Estrutura dos Scripts

### Script Principal
- **`exploit_all.sh`** - Executa todos os scripts de exploração de forma sequencial

### Scripts Específicos por Área

1. **`exploit_mysql.sh`** - Exploração MySQL
   - Brute force de credenciais
   - Exploração de vulnerabilidades conhecidas (CVE-2012-2122)
   - Extração de dados
   - Pós-exploração

2. **`exploit_ssh.sh`** - Exploração SSH
   - Brute force nas portas 22 e 2222
   - Enumeração de usuários
   - Exploração de vulnerabilidades OpenSSH
   - Pós-exploração e criação de backdoors

3. **`exploit_ftp.sh`** - Exploração FTP
   - Brute force de credenciais
   - Teste de login anônimo
   - Enumeração de diretórios
   - Download de arquivos sensíveis

4. **`exploit_joomla.sh`** - Exploração Joomla CMS
   - Brute force do painel administrativo
   - Teste de injeção SQL
   - Exploração de file inclusion (LFI/RFI)
   - Teste de upload de arquivos
   - Extração de configuration.php

5. **`exploit_email.sh`** - Exploração de Serviços de Email
   - Brute force POP3/POP3S/IMAP/IMAPS
   - Enumeração de usuários SMTP
   - Teste de Open Relay
   - Acesso a emails

6. **`exploit_web.sh`** - Exploração Web Geral
   - Enumeração de diretórios
   - Teste de XSS, SQL Injection, Command Injection
   - Teste de File Inclusion
   - Teste de upload de arquivos
   - Análise SSL/TLS

7. **`exploit_dns.sh`** - Exploração DNS
   - Enumeração de subdomínios
   - Tentativas de Zone Transfer
   - Teste de recursão DNS
   - Mapeamento de infraestrutura

## 🚀 Como Usar

### Pré-requisitos

- Sistema operacional: Kali Linux (recomendado) ou Debian/Ubuntu
- Privilégios: Alguns scripts podem precisar de `sudo`
- Conexão: Internet para download de ferramentas e wordlists

### Execução Rápida (Todos os Ataques)

```bash
cd script
sudo ./exploit_all.sh <DOMINIO> <IP>
# Exemplo: sudo ./exploit_all.sh exemplo.com.br 192.168.1.100
```

### Execução Individual

**Scripts que requerem DOMINIO e IP:**
```bash
sudo ./ataque_geral.sh <DOMINIO> <IP>
sudo ./ataque_mysql.sh <DOMINIO> <IP>
sudo ./ataque_ssh.sh <DOMINIO> <IP>
sudo ./ataque_smtp.sh <DOMINIO> <IP>
sudo ./exploit_mysql.sh <DOMINIO> <IP>
sudo ./exploit_ssh.sh <DOMINIO> <IP>
```

**Scripts que requerem apenas DOMINIO:**
```bash
sudo ./ataque_joomla.sh <DOMINIO>
sudo ./exploit_dns.sh <DOMINIO>
sudo ./exploit_email.sh <DOMINIO>
sudo ./exploit_ftp.sh <DOMINIO>
sudo ./exploit_joomla.sh <DOMINIO>
```

**Exemplos:**
```bash
sudo ./ataque_mysql.sh exemplo.com.br 192.168.1.100
sudo ./exploit_dns.sh exemplo.com.br
sudo ./exploit_joomla.sh exemplo.com.br
```

## 📁 Estrutura de Saída

Todos os scripts criam os seguintes diretórios:

- **`logs/`** - Logs detalhados de cada fase de exploração
- **`results/`** - Resultados importantes (credenciais, vulnerabilidades, arquivos extraídos)

### Arquivos Importantes

- `results/*credentials*.txt` - Credenciais encontradas
- `results/*vulnerabilit*.txt` - Vulnerabilidades identificadas
- `results/consolidated_report.txt` - Relatório consolidado (após executar exploit_all.sh)

## 🔧 Características dos Scripts

### Autonomia
- Verificam e instalam ferramentas automaticamente
- Baixam wordlists se necessário
- Executam de forma completamente autônoma

### Agressividade
- Múltiplas threads para brute force
- Múltiplas técnicas de exploração
- Tentativas de pós-exploração automáticas

### Robustez
- Tratamento de erros
- Logging detalhado
- Timeout para evitar travamentos

## 🛠️ Ferramentas Utilizadas

Os scripts utilizam as seguintes ferramentas do Kali Linux:

- **nmap** - Scanning de portas e serviços
- **hydra** - Brute force de credenciais
- **sqlmap** - Teste de injeção SQL
- **nikto** - Scanner de vulnerabilidades web
- **gobuster/dirb** - Enumeração de diretórios
- **metasploit** - Framework de exploração
- **dnsenum/dnsrecon** - Enumeração DNS
- **joomscan** - Scanner específico para Joomla
- E muitas outras...

## 📊 Áreas de Vulnerabilidade Atacadas

Os scripts focam nas seguintes áreas:

1. ✅ **MySQL** (porta 3306) - Brute force e exploração de vulnerabilidades conhecidas
2. ✅ **SSH** (portas 22, 2222) - Brute force e enumeração de usuários
3. ✅ **FTP** (porta 21) - Brute force e exploração de vulnerabilidades
4. ✅ **Joomla CMS** - Exploração do painel administrativo e vulnerabilidades web
5. ✅ **Serviços de Email** - POP3, IMAP, SMTP (brute force e enumeração)
6. ✅ **Apache HTTP** - Enumeração de diretórios e vulnerabilidades web
7. ✅ **DNS/BIND** - Enumeração de subdomínios e zone transfer

## ⚡ Performance

- **Tempo estimado**: 2-6 horas para execução completa (dependendo da conexão e recursos)
- **Threads**: Scripts usam múltiplas threads para acelerar processos
- **Wordlists**: Utilizam wordlists grandes (rockyou.txt com milhões de senhas)

## 🔍 Monitoramento

Durante a execução, você pode monitorar:

```bash
# Ver logs em tempo real
tail -f logs/main_exploitation.log

# Ver resultados encontrados
ls -la results/

# Verificar credenciais encontradas
grep -r "SUCESSO" results/
```

## 📝 Notas Importantes

1. **Autorização**: Certifique-se de ter autorização escrita antes de executar
2. **Ambiente**: Execute em ambiente controlado (lab de pentest)
3. **Recursos**: Scripts são intensivos em CPU/rede
4. **Detecção**: Atividades podem ser detectadas por sistemas de segurança
5. **Logs**: Todos os logs são salvos localmente

## 🐛 Troubleshooting

### Script não executa
```bash
chmod +x *.sh
```

### Ferramenta não encontrada
```bash
sudo apt-get update
sudo apt-get install -y [nome_da_ferramenta]
```

### Permissão negada
```bash
sudo ./exploit_all.sh
```

### Timeout em scripts
- Aumente o timeout no script (padrão: 3600 segundos)
- Verifique conexão de rede
- Reduza número de threads se necessário

## 📞 Suporte

Para questões sobre os scripts, consulte:
- Logs em `logs/`
- Documentação das ferramentas individuais
- Relatório de análise original

---

**Nota**: Todos os scripts agora solicitam o domínio e/ou IP como parâmetros, permitindo que sejam utilizados em qualquer ambiente autorizado.

