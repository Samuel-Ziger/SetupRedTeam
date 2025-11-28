# ⚡ Guia Rápido - Novas Funcionalidades

## 🚀 Começar em 5 Minutos

### **1. Dar Permissões** (Executar UMA VEZ)
```bash
cd ~/Documents/Scripts
chmod +x lib/*.sh
chmod +x ScrpitPentestSH/retestesh/reteste_with_opsec.sh
```

### **2. Testar OPSEC Check**
```bash
source lib/opsec.sh
pre_engagement_check
```

### **3. Fazer Primeiro Backup**
```bash
./lib/backup_tools.sh
# Escolher opção 5 (Backup completo)
```

---

## 📋 Comandos Mais Usados

### **OPSEC - Antes de Pentest**
```bash
# Checklist completo
source lib/opsec.sh && pre_engagement_check

# Verificar VPN
check_vpn

# Verificar recursos
source lib/resource_check.sh && full_system_check
```

### **Backup**
```bash
# Menu interativo
./lib/backup_tools.sh

# Backup completo direto
cd lib && ./backup_tools.sh
# Opção 5
```

### **Relatórios**
```bash
# Gerar relatório do zero
./lib/generate_report.sh

# Converter Markdown existente para PDF
./lib/generate_report.sh
# Opção 3
```

### **Reteste com OPSEC**
```bash
cd ScrpitPentestSH/retestesh
./reteste_with_opsec.sh
```

---

## 🛠️ Instalações Opcionais

### **Pandoc (Para PDFs)**
```bash
sudo apt install pandoc
# OU com LaTeX completo:
sudo apt install pandoc texlive-latex-base texlive-fonts-recommended
```

### **Wazuh SIEM**
```bash
./lib/install_wazuh.sh
# Acesso: https://localhost
# User: admin / Pass: SecretPassword
```

### **C2 Modernos + Cloud Tools (Kali)**
```bash
cd Kali
sudo ./setup-kali.sh
# Instala automaticamente Sliver, Pacu, Prowler, etc.
```

---

## 📁 Onde Está Cada Coisa

```
lib/
├── opsec.sh           → Segurança operacional
├── backup_tools.sh    → Backups automatizados
├── resource_check.sh  → Verificar CPU/RAM/Disco
├── generate_report.sh → Gerar relatórios PDF
└── install_wazuh.sh   → Instalar SIEM

docs/
├── OPSEC_CHECKLIST.md   → Checklist completo
├── BACKUP_STRATEGY.md   → Estratégia de backup
└── UPGRADE_GUIDE.md     → Guia de hardware

templates/
└── report_template.md   → Template de relatório

.github/workflows/
└── reteste.yml          → CI/CD automático

ScrpitPentestSH/retestesh/
└── reteste_with_opsec.sh → Wrapper OPSEC
```

---

## ⚙️ Configurar CI/CD (GitHub)

### **Passo 1: Adicionar Webhooks (Opcional)**
GitHub → Settings → Secrets → New secret

| Nome | Valor |
|------|-------|
| `DISCORD_WEBHOOK` | URL do webhook Discord |
| `SLACK_WEBHOOK` | URL do webhook Slack |

### **Passo 2: Ativar Actions**
GitHub → Actions → Enable workflows

### **Passo 3: Testar**
Actions → Reteste Automatizado → Run workflow

---

## 🔍 Troubleshooting Rápido

| Problema | Solução |
|----------|---------|
| "Permission denied" | `chmod +x lib/*.sh` |
| "source: not found" | Use `bash script.sh` ao invés de `./script.sh` |
| "Pandoc not found" | `sudo apt install pandoc` |
| "Docker not running" | `sudo systemctl start docker` |
| Scripts não acham lib/ | Execute do diretório raiz: `cd ~/Documents/Scripts` |

---

## 💡 Dicas

1. **Sempre execute do diretório raiz** (`~/Documents/Scripts`)
2. **Use `source`** para bibliotecas: `source lib/opsec.sh`
3. **Teste antes de usar em produção**
4. **Leia os guias em `docs/`** para detalhes

---

## 📚 Documentação Completa

- `NOVAS_FUNCIONALIDADES.md` - Lista completa de adições
- `docs/OPSEC_CHECKLIST.md` - Checklist de segurança
- `docs/BACKUP_STRATEGY.md` - Estratégia de backup
- `docs/UPGRADE_GUIDE.md` - Hardware upgrades

---

**Atualizado:** 2025-11-28
