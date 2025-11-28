# 💾 Estratégia de Backup - Red Team Arsenal

## 🎯 Objetivo

Proteger **anos de trabalho** em ferramentas, scripts, configurações e dados contra:
- 💥 Falha de hardware (HD/SSD queimando)
- 🔥 Ransomware / Malware
- 🗑️ Deleção acidental
- ⚡ Perda de energia durante operação
- 🔧 Corrupção de arquivos

---

## 📊 **Estratégia 3-2-1**

### **Regra de Ouro:**
- **3** cópias dos dados (original + 2 backups)
- **2** mídias diferentes (SSD + HD externo, ou SSD + NAS, ou SSD + Cloud)
- **1** cópia offsite (nuvem, outra localização física)

---

## 📁 **O Que Fazer Backup**

### **🔴 CRÍTICO** (Backup Diário/Semanal)

| Item | Tamanho Aprox | Prioridade | Método |
|------|---------------|------------|--------|
| Scripts customizados | ~100 MB | 🔴 MÁXIMA | Git + rsync |
| Configurações (dotfiles) | ~10 MB | 🔴 MÁXIMA | Git |
| Wordlists customizadas | ~500 MB | 🔴 ALTA | rsync |
| Relatórios de pentests | ~1 GB | 🔴 MÁXIMA | Criptografado |
| Evidências (screenshots) | ~2 GB | 🔴 MÁXIMA | Criptografado |
| Notas/Anotações | ~50 MB | 🔴 ALTA | Git/Obsidian sync |

**Total crítico:** ~3.6 GB

---

### **🟡 IMPORTANTE** (Backup Semanal/Mensal)

| Item | Tamanho Aprox | Prioridade | Método |
|------|---------------|------------|--------|
| VMs Proxmox (snapshots) | ~50-100 GB | 🟡 ALTA | vzdump |
| Ferramentas Kali (29 tools) | ~312 MB | 🟡 MÉDIA | rsync |
| Exploits/PoCs compilados | ~500 MB | 🟡 MÉDIA | Git LFS |
| Databases de vulnerabilidades | ~1 GB | 🟡 MÉDIA | rsync |

**Total importante:** ~51-101 GB

---

### **🟢 RECUPERÁVEL** (Backup Mensal/Trimestral)

| Item | Tamanho Aprox | Prioridade | Método |
|------|---------------|------------|--------|
| SecLists (wordlists) | ~1.2 GB | 🟢 BAIXA | Git clone |
| Metasploit modules | ~500 MB | 🟢 BAIXA | apt install |
| Ferramentas públicas | Varia | 🟢 BAIXA | Git clone |
| ISOs de sistemas | ~5-10 GB | 🟢 BAIXA | Download |

**Total recuperável:** ~7-12 GB  
**Nota:** Pode ser re-baixado da internet se perder.

---

## 🔧 **Implementação Prática**

### **1. Backup Local (Diário) - HD Externo/NAS**

```bash
#!/bin/bash
# Adicionar ao crontab: 0 2 * * * /path/to/backup_daily.sh

source lib/backup_tools.sh

# Backup de scripts customizados
backup_custom_scripts

# Backup de configurações
rsync -av --delete ~/.bashrc ~/.zshrc ~/.vimrc /mnt/backup/dotfiles/

# Git auto-commit
cd ~/Documents/Scripts
git add .
git commit -m "Auto-backup $(date +%Y-%m-%d)"
```

**Cron job:**
```cron
# Backup diário às 2h da manhã
0 2 * * * /home/user/scripts/backup_daily.sh >> /var/log/backup.log 2>&1
```

---

### **2. Backup Remoto (Semanal) - Cloud**

```bash
#!/bin/bash
# Cron: 0 3 * * 0 (todo domingo às 3h)

# Sincronizar com Google Drive / OneDrive / Dropbox
rclone sync ~/Documents/Scripts gdrive:RedTeam/Scripts \
    --exclude '*.pyc' \
    --exclude '__pycache__' \
    --exclude 'Kali/Ferramentas' \
    --progress

# Sincronizar evidências CRIPTOGRAFADAS
tar -czf - ~/Documents/Evidencias | \
    openssl enc -aes-256-cbc -salt -pbkdf2 -out evidencias_$(date +%Y%m%d).tar.gz.enc

rclone copy evidencias_$(date +%Y%m%d).tar.gz.enc gdrive:RedTeam/Evidencias/
```

**Configurar rclone:**
```bash
# Instalar
sudo apt install rclone

# Configurar Google Drive
rclone config

# Testar
rclone ls gdrive:
```

---

### **3. Backup de VMs Proxmox (Semanal)**

```bash
#!/bin/bash
# Executar NO SERVIDOR PROXMOX

BACKUP_DIR="/var/lib/vz/dump"
REMOTE_NAS="user@nas:/mnt/backups/proxmox/"

# Backup de todas as VMs
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
    echo "Backup VM $vmid..."
    vzdump $vmid --compress gzip --mode snapshot --storage local
done

# Copiar para NAS remoto
rsync -av --progress $BACKUP_DIR/ $REMOTE_NAS

# Limpar backups >30 dias
find $BACKUP_DIR -name "*.vma.gz" -mtime +30 -delete
```

**Cron no Proxmox:**
```cron
# Backup VMs todo domingo 4h
0 4 * * 0 /root/backup_vms.sh >> /var/log/vm_backup.log 2>&1
```

---

### **4. Git como Backup (Contínuo)**

```bash
# Configurar Git para auto-push
cd ~/Documents/Scripts

# Hook post-commit para auto-push
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
git push origin main
EOF

chmod +x .git/hooks/post-commit

# Agora todo commit faz push automático
git add .
git commit -m "Update scripts"
# Push automático!
```

---

## 🔐 **Criptografia de Backups**

### **Criptografar diretório completo**

```bash
# Criar backup criptografado
tar -czf - ~/Documents/Scripts | \
    openssl enc -aes-256-cbc -salt -pbkdf2 \
    -out scripts_backup_$(date +%Y%m%d).tar.gz.enc

# Descriptografar depois
openssl enc -aes-256-cbc -d -pbkdf2 \
    -in scripts_backup_20251128.tar.gz.enc | \
    tar -xzf -
```

### **Usar VeraCrypt para volume criptografado**

```bash
# Instalar VeraCrypt
sudo apt install veracrypt

# Criar volume criptografado de 50GB
veracrypt --text --create /mnt/backup/encrypted_vault.vc --size 50G

# Montar
veracrypt /mnt/backup/encrypted_vault.vc /mnt/secure_backup/
```

---

## 📅 **Cronograma de Backup**

| Frequência | O Que | Onde | Retenção |
|------------|-------|------|----------|
| **Diário** | Scripts + Configs | HD Externo | 30 dias |
| **Semanal** | Scripts + Evidências | Cloud (criptografado) | 90 dias |
| **Semanal** | VMs Proxmox | NAS | 30 dias |
| **Mensal** | Ferramentas completas | HD Externo | 180 dias |
| **Trimestral** | Backup completo | HD Externo offsite | 1 ano |

---

## 🧪 **Testar Recuperação**

### **Regra:** Se não testou, não tem backup!

```bash
# Teste mensal de restauração
# 1. Escolher arquivo aleatório
# 2. Deletar cópia local
# 3. Restaurar do backup
# 4. Verificar integridade

# Exemplo:
rm ~/Documents/Scripts/lib/opsec.sh
rsync -av /mnt/backup/Scripts/lib/opsec.sh ~/Documents/Scripts/lib/
diff ~/Documents/Scripts/lib/opsec.sh /mnt/backup/Scripts/lib/opsec.sh
```

**Criar alerta para teste:**
```cron
# Lembrete mensal para testar backup (dia 1 de cada mês)
0 9 1 * * notify-send "🔔 TESTAR BACKUP HOJE!"
```

---

## 🛠️ **Ferramentas Recomendadas**

### **Backup Local**
- **rsync** - Sync inteligente (copia só diferenças)
- **Timeshift** - Snapshots do sistema (Kali/Ubuntu)
- **Clonezilla** - Clonagem completa de discos

### **Backup Cloud**
- **rclone** - Suporta 40+ provedores (Drive, Dropbox, OneDrive, S3)
- **Duplicity** - Backup incremental criptografado
- **Restic** - Backup moderno e rápido

### **Criptografia**
- **OpenSSL** - Criptografia de arquivos
- **VeraCrypt** - Volumes criptografados
- **GnuPG** - Criptografia PGP

### **Automação**
- **Cron** - Agendamento de tarefas
- **Systemd timers** - Alternativa moderna ao cron
- **Ansible** - Automação de backups em múltiplas máquinas

---

## 💾 **Mídia de Backup Recomendada**

### **Para seu setup:**

**PC1 (Proxmox):**
- ✅ NAS ou HD externo USB 3.0 (2-4 TB)
- ✅ Cloud (Google Drive ilimitado edu, ou S3)

**PC2/Notebooks:**
- ✅ HD externo portátil (1-2 TB)
- ✅ Git + GitHub private repo
- ✅ Cloud sincronizado

**Offsite:**
- ✅ HD externo na casa de familiar
- ✅ Cloud (Mega, pCloud, Backblaze B2)

---

## 🚨 **Checklist Pós-Desastre**

Se perder tudo, ordem de recuperação:

1. ✅ **Reinstalar OS** (Kali/Windows/Proxmox)
2. ✅ **Clonar repo do GitHub** (`git clone ...`)
3. ✅ **Executar scripts de setup** (`setup-kali.sh`, `atack2.0.bat`)
4. ✅ **Restaurar backups locais** (evidências, relatórios)
5. ✅ **Baixar ferramentas públicas** (SecLists, Metasploit)
6. ✅ **Restaurar VMs** (vzdump restore)
7. ✅ **Reconfigurar C2** (Sliver, Mythic)

**Tempo estimado:** 4-8 horas

---

## 📊 **Monitoramento de Backups**

```bash
# Script de verificação (rodar mensalmente)
#!/bin/bash

echo "=== Verificação de Backups ==="
echo ""

# Último backup local
echo "Último backup local:"
ls -lh /mnt/backup/Scripts/ | tail -1

# Último backup cloud
echo "Último backup cloud:"
rclone lsl gdrive:RedTeam/Scripts | tail -1

# Espaço usado
echo "Espaço em backups:"
du -sh /mnt/backup/

# Idade do último backup
LAST_BACKUP=$(find /mnt/backup/Scripts -type f -printf '%T+ %p\n' | sort -r | head -1 | cut -d' ' -f1)
echo "Último arquivo modificado: $LAST_BACKUP"

# Alerta se >7 dias
DAYS_OLD=$(( ($(date +%s) - $(date -d "$LAST_BACKUP" +%s)) / 86400 ))
if [ $DAYS_OLD -gt 7 ]; then
    echo "⚠️ ALERTA: Backup com $DAYS_OLD dias!"
fi
```

---

## 📝 **Script de Backup Completo**

Veja `lib/backup_tools.sh` para script interativo completo.

```bash
# Executar
chmod +x lib/backup_tools.sh
./lib/backup_tools.sh

# Opções:
# 1) Backup Ferramentas Kali
# 2) Backup VMs Proxmox
# 3) Backup Wordlists
# 4) Backup Scripts
# 5) BACKUP COMPLETO
```

---

**Última atualização:** 2025-11-28  
**Autor:** Samuel Ziger

**Lembre-se:** Backup é seguro, mas backup testado é garantia!
