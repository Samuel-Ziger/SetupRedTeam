# 🎯 Pipeline de Reconhecimento Automatizado

Script de automação robusto, modular e persistente para reconhecimento contínuo em pentest autorizado e bug bounty.

## 📋 Visão Geral

Este pipeline automatiza o processo completo de reconhecimento de superfícies de ataque, executando ferramentas de enumeração, descoberta e scan de vulnerabilidades de forma incremental e persistente.

## 🛠 Ferramentas Utilizadas

- **Subdomain Enumeration**: `subfinder`, `assetfinder`, `amass`
- **DNS Resolution**: `dnsx`
- **HTTP Discovery**: `httpx`
- **URL Collection**: `gau`, `katana`, `uro`
- **Filtering**: `gf` (xss, sqli, lfi, ssrf, etc)
- **Port Scanning**: `naabu`, `nmap`
- **Vulnerability Scanning**: `nuclei`
- **Utilities**: `anew`, `notify`

## 📁 Estrutura de Diretórios

```
recon/
└── dominio.com/
    ├── subs/
    │   ├── subfinder.txt
    │   ├── assetfinder.txt
    │   ├── amass.txt
    │   └── subs_final.txt
    ├── dns/
    │   └── dnsx.txt
    ├── http/
    │   └── httpx.txt
    ├── urls/
    │   ├── gau.txt
    │   ├── katana.txt
    │   └── urls_final.txt
    ├── ports/
    │   ├── naabu.txt
    │   └── nmap.txt
    ├── vulns/
    │   ├── nuclei.txt
    │   └── gf/
    └── logs/
        └── recon.log
```

## 🚀 Instalação

### 1. Pré-requisitos

Instale todas as ferramentas necessárias:

```bash
# Instalar Go tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/tomnomnom/assetfinder@latest
go install -v github.com/owasp-amass/amass/v4/...@master
go install -v github.com/tomnomnom/anew@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/projectdiscovery/katana/cmd/katana@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/tomnomnom/gf@latest
go install -v github.com/projectdiscovery/notify/cmd/notify@latest

# Instalar outras ferramentas
pip3 install uro

# Instalar gf patterns
mkdir -p ~/.gf
git clone https://github.com/1ndianl33t/Gf-Patterns ~/.gf
```

### 2. Configuração

1. **Edite `domains.txt`** e adicione seus domínios alvo (um por linha):
   ```
   example.com
   target.com
   ```

2. **Configure Discord Webhook** (opcional):
   ```bash
   export DISCORD_WEBHOOK="https://discord.com/api/webhooks/YOUR_WEBHOOK"
   ```
   
   Ou edite a variável `DISCORD_WEBHOOK` no início do `recon.sh`.

3. **Torne o script executável**:
   ```bash
   chmod +x recon.sh install_cron.sh
   ```

## 📖 Uso

### Execução Manual

**Processar todos os domínios do arquivo `domains.txt`**:
```bash
./recon.sh
```

**Processar um domínio específico**:
```bash
./recon.sh example.com
```

### Execução Automática (Crontab)

**Instalar no crontab (executa a cada 6 horas)**:
```bash
./install_cron.sh
```

**Instalar com intervalo personalizado**:
```bash
# A cada 12 horas
./install_cron.sh "0 */12 * * *"

# Diariamente às 02:00
./install_cron.sh "0 2 * * *"

# A cada 4 horas
./install_cron.sh "0 */4 * * *"
```

**Verificar crontab**:
```bash
crontab -l
```

**Remover do crontab**:
```bash
crontab -e
# Remover a linha correspondente
```

## 🔄 Pipeline de Execução

Para cada domínio, o script executa:

1. **Enumeração de Subdomínios**
   - `subfinder`, `assetfinder`, `amass`
   - Unificação com `anew` (sem duplicações)

2. **Resolução DNS**
   - `dnsx` apenas nos subdomínios válidos
   - Filtra subdomínios que não resolvem

3. **Descoberta HTTP**
   - `httpx` com status code, título e tecnologia
   - Identifica hosts ativos

4. **Coleta de URLs**
   - `gau` e `katana` para crawling
   - Normalização com `uro`

5. **Filtragem Inteligente**
   - `gf` para padrões comuns (xss, sqli, lfi, ssrf, etc)

6. **Port Scanning**
   - `naabu` para descoberta rápida
   - `nmap` agressivo nos hosts descobertos

7. **Scan de Vulnerabilidades**
   - `nuclei` com templates atualizados
   - Output por severidade

## 🔔 Notificações Discord

O script envia notificações automáticas quando:

- ✅ Novos subdomínios são encontrados
- 🌐 Novos hosts HTTP são descobertos
- 🚨 Vulnerabilidades são detectadas

**Configurar Webhook**:
1. Crie um webhook no Discord (Configurações do Servidor → Integrações → Webhooks)
2. Configure a variável de ambiente:
   ```bash
   export DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
   ```
3. Ou edite `DISCORD_WEBHOOK` no script

## 📊 Logs

Todos os logs são salvos em:
- `recon/*/logs/recon.log` - Logs por domínio
- `cron.log` - Logs da execução via crontab

## ⚙️ Configurações Avançadas

Edite as variáveis no início do `recon.sh`:

```bash
SUBFINDER_THREADS=10
AMASS_TIMEOUT=30m
NAABU_RATE=1000
NUCLEI_SEVERITY="info,low,medium,high,critical"
NUCLEI_RATE=150
HTTPX_THREADS=50
```

## 🛡 Boas Práticas Implementadas

- ✅ `set -euo pipefail` para tratamento de erros
- ✅ Verificação de dependências no início
- ✅ Logs claros e timestampados
- ✅ Script idempotente (executável múltiplas vezes)
- ✅ Uso de `anew` para evitar duplicações
- ✅ Lockfile para evitar execuções simultâneas
- ✅ Validação de entrada
- ✅ Código modular e organizado

## ⚠️ Aviso Legal

Este script é destinado exclusivamente para:

- ✅ Ambientes autorizados
- ✅ Bug bounty (com autorização)
- ✅ Testes internos

**NÃO** inclui funcionalidades destrutivas e deve ser usado apenas em ambientes onde você tem autorização explícita para realizar testes de segurança.

## 🔧 Troubleshooting

**Erro: "Comando não encontrado"**
- Instale as ferramentas faltantes conforme pré-requisitos

**Erro: "Lockfile em execução"**
- Um processo anterior pode ter travado. Remova manualmente: `rm .recon.lock`

**Notificações Discord não funcionam**
- Verifique se `DISCORD_WEBHOOK` está configurado corretamente
- Teste com: `echo 'test' | notify -provider discord -id discord`

**Resultados vazios**
- Verifique os logs em `recon/*/logs/recon.log`
- Algumas ferramentas podem precisar de configuração adicional (chaves API, etc)

## 📝 Notas

- O script usa `anew` para evitar duplicações em todas as etapas
- Execuções subsequentes apenas adicionam novos resultados
- Resultados anteriores são preservados
- Lockfile previne execuções simultâneas

## 🤝 Contribuições

Para melhorias e correções, mantenha o código modular e documentado.

---

**Desenvolvido com foco em operações Red Team profissionais** 🔴

