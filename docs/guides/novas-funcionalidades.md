# 🆕 Novas Funcionalidades - Atualização 2025-11-28

## 📦 O Que Foi Adicionado

### **1. Biblioteca OPSEC** (`lib/opsec.sh`)
Sistema completo de segurança operacional para pentests.

**Funções disponíveis:**
- `check_vpn [IP_ESPERADO]` - Verificar se VPN está ativa
- `vpn_killswitch [IP_ESPERADO]` - Abortar se VPN cair
- `check_dns_leak` - Detectar vazamento de DNS
- `rate_limit [MIN] [MAX]` - Delay aleatório entre requests
- `random_user_agent` - Gerar User-Agent aleatório
- `check_root` - Verificar se é root
- `check_dependencies [TOOLS...]` - Verificar ferramentas instaladas
- `sanitize_input [STRING]` - Prevenir injection
- `validate_target [IP/DOMAIN]` - Validar alvos
- `pre_engagement_check` - Checklist completo pré-operação

**Uso:**
```bash
source lib/opsec.sh
pre_engagement_check
```

---

### **2. Sistema de Backup Automatizado** (`lib/backup_tools.sh`)
Backup profissional de ferramentas, VMs, scripts e wordlists.

**Recursos:**
- Backup das 29 ferramentas Kali (~312MB)
- Backup de VMs Proxmox
- Backup de wordlists (SecLists)
- Backup de scripts customizados + Git auto-commit
- Limpeza automática de backups antigos (>30 dias)
- Verificação de integridade

**Uso:**
```bash
chmod +x lib/backup_tools.sh
./lib/backup_tools.sh
```

---

### **3. Verificação de Recursos** (`lib/resource_check.sh`)
Detecta gargalos de hardware antes de executar operações pesadas.

**Verifica:**
- CPU (modelo, cores, uso atual)
- RAM (total, usado, disponível)
- Disco (espaço livre)
- SWAP (uso)
- Detecta automaticamente PC1, PC2, NB1, NB2

**Uso:**
```bash
source lib/resource_check.sh
full_system_check

# Verificar se pode executar operação
can_run_operation "masscan"
```

---

### **4. Gerador de Relatórios** (`lib/generate_report.sh`)
Converte outputs de reteste em relatórios profissionais (Markdown → PDF).

**Recursos:**
- Templates profissionais
- Conversão automática Markdown → PDF
- Conversão Markdown → HTML
- Processamento de outputs de reteste

**Uso:**
```bash
chmod +x lib/generate_report.sh
./lib/generate_report.sh
```

**Dependências:**
```bash
sudo apt install pandoc texlive-latex-base
```

---

### **5. C2 Frameworks Modernos** (Kali)
Adicionado ao `setup-kali.sh`:

- **Sliver** - C2 moderno em Go (substituiu Cobalt Strike)
- **Havoc** - C2 open-source profissional
- **Mythic** - Framework modular de C2

**Instalação:**
```bash
# Já está no setup-kali.sh atualizado
sudo ./Kali/setup-kali.sh
```

---

### **6. Cloud Security Tools** (Kali)
Ferramentas para pentesting em AWS/Azure/GCP.

- **Pacu** - AWS exploitation framework
- **ScoutSuite** - Multi-cloud auditing
- **Prowler** - AWS/Azure/GCP security assessment
- **CloudFox** - AWS situational awareness

**Uso:**
```bash
# Pacu (AWS)
cd ~/Tools/pacu && python pacu.py

# ScoutSuite
scout aws

# Prowler
prowler aws

# CloudFox
cloudfox aws whoami
```

---

### **7. Wazuh SIEM** (`lib/install_wazuh.sh`)
SIEM open-source para logging centralizado via Docker.

**Recursos:**
- Dashboard web (https://localhost)
- Log aggregation
- Threat detection
- Compliance monitoring

**Instalação:**
```bash
chmod +x lib/install_wazuh.sh
./lib/install_wazuh.sh
```

**Acesso:**
- URL: https://localhost
- User: admin
- Pass: SecretPassword (trocar após login!)

---

### **8. CI/CD GitHub Actions** (`.github/workflows/reteste.yml`)
Reteste automatizado semanal com notificações.

**Recursos:**
- Execução automática todo domingo 2h
- Execução manual sob demanda
- Notificações Discord/Slack
- Upload de relatórios como artifacts

**Configurar:**
1. No GitHub, vá em Settings → Secrets
2. Adicione (opcional):
   - `DISCORD_WEBHOOK` - URL do webhook Discord
   - `SLACK_WEBHOOK` - URL do webhook Slack
3. Workflow executa automaticamente

---

### **9. Wrapper OPSEC para Retestes** (`retestesh/reteste_with_opsec.sh`)
Adiciona segurança operacional aos scripts de reteste SEM modificá-los.

**Recursos:**
- VPN check antes de executar
- Rate limiting automático
- User-Agent rotation
- Resource checking

**Uso:**
```bash
cd ScrpitPentestSH/retestesh
chmod +x reteste_with_opsec.sh
./reteste_with_opsec.sh
```

---

### **10. Documentação Completa** (`docs/`)
Guias profissionais para cada aspecto do arsenal.

**Arquivos:**
- `OPSEC_CHECKLIST.md` - Checklist de segurança operacional
- `BACKUP_STRATEGY.md` - Estratégia 3-2-1 de backup
- `UPGRADE_GUIDE.md` - Guia de upgrade de hardware priorizado

---

## 🚀 **Como Usar Tudo Isso**

### **Setup Inicial (Uma vez)**
```bash
# 1. Dar permissão aos scripts
chmod +x lib/*.sh
chmod +x ScrpitPentestSH/retestesh/*.sh

# 2. Atualizar Kali com novidades
cd Kali
sudo ./setup-kali.sh

# 3. Configurar backup
./lib/backup_tools.sh
# Escolher opção 5 (Backup completo)

# 4. (Opcional) Instalar Wazuh para logging
./lib/install_wazuh.sh
```

---

### **Uso Diário - Workflow Recomendado**

#### **ANTES de começar pentest:**
```bash
# Pre-flight check completo
source lib/opsec.sh
pre_engagement_check

# Verificar recursos
source lib/resource_check.sh
full_system_check
```

#### **DURANTE pentest:**
```bash
# Executar reteste com OPSEC
cd ScrpitPentestSH/retestesh
./reteste_with_opsec.sh
```

#### **DEPOIS do pentest:**
```bash
# Gerar relatório profissional
./lib/generate_report.sh

# Fazer backup
./lib/backup_tools.sh
```

---

## 📊 **Estatísticas da Atualização**

| Item | Quantidade |
|------|------------|
| **Novos scripts** | 7 |
| **Novas bibliotecas** | 4 |
| **Novos guias** | 3 |
| **Novas ferramentas** | 7 (C2 + Cloud) |
| **Linhas de código** | ~3,500 |
| **Funções OPSEC** | 10 |

---

## 🔧 **Arquivos Modificados**

```
NOVOS ARQUIVOS:
├── lib/
│   ├── opsec.sh                  ⭐ Biblioteca OPSEC
│   ├── backup_tools.sh           ⭐ Sistema de backup
│   ├── resource_check.sh         ⭐ Verificação de recursos
│   ├── generate_report.sh        ⭐ Gerador de relatórios
│   └── install_wazuh.sh          ⭐ Instalador Wazuh SIEM
│
├── docs/
│   ├── OPSEC_CHECKLIST.md        ⭐ Checklist operacional
│   ├── BACKUP_STRATEGY.md        ⭐ Guia de backup
│   └── UPGRADE_GUIDE.md          ⭐ Guia de hardware
│
├── templates/
│   └── report_template.md        ⭐ Template de relatório
│
├── .github/workflows/
│   └── reteste.yml               ⭐ CI/CD automatizado
│
└── ScrpitPentestSH/retestesh/
    └── reteste_with_opsec.sh     ⭐ Wrapper OPSEC

ARQUIVOS ATUALIZADOS:
├── Kali/setup-kali.sh            ✏️ +C2 modernos +Cloud tools
└── README.md                     ✏️ (a ser atualizado)
```

---

## ⚠️ **Notas Importantes**

### **1. Seus Scripts Originais NÃO Foram Tocados**
✅ Todos os seus scripts em:
- `ScrpitPentestSH/retestesh/reteste_*.sh`
- `Windows/atack2.0-optimized.bat`
- `Kali/Ferramentas/*`

Permanecem **100% intactos**. Tudo que adicionei são **arquivos novos** ou **adições no final** de scripts existentes.

### **2. Compatibilidade**
✅ Todos os scripts novos são **retrocompatíveis**
✅ Você pode usar ou não usar, sem quebrar nada
✅ Podem ser deletados sem afetar scripts antigos

### **3. Dependências Opcionais**
Algumas funcionalidades precisam de instalação manual:
```bash
# Para relatórios PDF
sudo apt install pandoc texlive-latex-base

# Para C2s (já no setup-kali.sh atualizado)
curl https://sliver.sh/install | sudo bash

# Para Wazuh (script automatizado)
./lib/install_wazuh.sh
```

---

## 🎯 **Próximos Passos Recomendados**

1. ✅ **Testar biblioteca OPSEC**
   ```bash
   source lib/opsec.sh
   pre_engagement_check
   ```

2. ✅ **Configurar backup**
   ```bash
   ./lib/backup_tools.sh
   # Escolher pasta de backup
   # Executar backup completo
   ```

3. ✅ **Atualizar Kali**
   ```bash
   cd Kali
   sudo ./setup-kali.sh
   # Instala C2s + Cloud tools
   ```

4. ✅ **Testar geração de relatório**
   ```bash
   ./lib/generate_report.sh
   # Opção 1: Criar do zero
   ```

5. ✅ **Configurar CI/CD** (opcional)
   - GitHub → Settings → Secrets
   - Adicionar webhooks Discord/Slack

---

## 📞 **Suporte**

### **Problemas Comuns**

**"Permission denied" em scripts:**
```bash
chmod +x lib/*.sh
chmod +x ScrpitPentestSH/retestesh/*.sh
```

**"Pandoc not found":**
```bash
sudo apt install pandoc
```

**"Docker not running" (Wazuh):**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

---

## 🔥 **Resumo das Melhorias**

| Antes | Depois |
|-------|--------|
| ❌ Sem OPSEC automatizado | ✅ Biblioteca completa OPSEC |
| ❌ Backup manual | ✅ Sistema automatizado |
| ❌ Relatórios .txt apenas | ✅ PDF profissionais |
| ❌ Sem C2 moderno | ✅ Sliver, Havoc, Mythic |
| ❌ Sem cloud tools | ✅ Pacu, Prowler, ScoutSuite |
| ❌ Sem logging centralizado | ✅ Wazuh SIEM |
| ❌ Retestes manuais | ✅ CI/CD automatizado |
| ❌ Sem verificação de recursos | ✅ Detecta gargalos |

---

**Data:** 2025-11-28  
**Versão:** 2.0  
**Autor:** Samuel Ziger (com assistência de IA)

**🎉 Parabéns! Seu arsenal Red Team foi atualizado para nível profissional!**
