#!/bin/bash

################################################################################
#                                                                              #
#  NOTEBOOK 1 - STEALTH BOX SETUP                                             #
#  Sistema: Kali Linux XFCE Minimal (leve, rápido)                            #
#  Função: Máquina stealth - pivot local - phishing - servidor leve           #
#                                                                              #
#  ⚠️  AVISO LEGAL: USE APENAS COM AUTORIZAÇÃO FORMAL POR ESCRITO!            #
#                                                                              #
################################################################################

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Verificar se é root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] Este script precisa ser executado como root!${NC}"
   echo -e "${YELLOW}Execute: sudo $0${NC}"
   exit 1
fi

clear
echo -e "${CYAN}${BOLD}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║              NOTEBOOK 1 - STEALTH BOX SETUP                                ║
║                    Kali XFCE Minimal                                        ║
║                                                                            ║
║  Função: Máquina stealth - pivot - reverse shell host - servidor leve    ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}[i] Este script irá configurar o Notebook 1 como Stealth Box${NC}"
echo -e "${YELLOW}[i] Tempo estimado: 20-30 minutos${NC}"
echo ""
read -p "Continuar? (s/N): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo -e "${RED}[!] Instalação cancelada${NC}"
    exit 0
fi

# Diretórios base
NB1_HOME="/opt/notebook1"
NB1_PAYLOADS="${NB1_HOME}/payloads"
NB1_LOGS="${NB1_HOME}/logs"
NB1_SCRIPTS="${NB1_HOME}/scripts"
NB1_WWW="${NB1_HOME}/www"

# Criar estrutura de diretórios
echo -e "${BLUE}[1/15] Criando estrutura de diretórios...${NC}"
mkdir -p "$NB1_HOME" "$NB1_PAYLOADS" "$NB1_LOGS" "$NB1_SCRIPTS" "$NB1_WWW"
mkdir -p "$NB1_PAYLOADS"/{windows,linux,web,office}
mkdir -p "$NB1_WWW"/{downloads,uploads,phishing}
chmod 755 "$NB1_HOME"
chmod 700 "$NB1_PAYLOADS"
chmod 755 "$NB1_WWW"

# Atualizar sistema (opcional - pode ser demorado)
echo -e "${BLUE}[2/15] Atualizando sistema...${NC}"
echo -e "${YELLOW}[i] Esta etapa pode demorar alguns minutos...${NC}"
echo -e "${YELLOW}[i] Você pode pular se o sistema já estiver atualizado${NC}"
read -p "Atualizar sistema agora? (S/n): " update_confirm
if [[ ! "$update_confirm" =~ ^[Nn]$ ]]; then
    echo -e "${BLUE}[*] Executando apt update...${NC}"
    timeout 300 apt update 2>&1 | grep -E "(Reading|Fetched|Get:|Hit:|Ign:|Err)" || {
        echo -e "${YELLOW}[!] apt update demorou muito ou falhou. Continuando...${NC}"
    }
    
    echo -e "${BLUE}[*] Executando apt upgrade (pode demorar)...${NC}"
    echo -e "${YELLOW}[i] Isso pode levar 10-30 minutos dependendo do sistema${NC}"
    DEBIAN_FRONTEND=noninteractive timeout 1800 apt upgrade -y 2>&1 | grep -E "(Reading|Setting up|Unpacking|Processing)" || {
        echo -e "${YELLOW}[!] apt upgrade demorou muito ou foi interrompido. Continuando...${NC}"
    }
    echo -e "${GREEN}[✓] Atualização concluída${NC}"
else
    echo -e "${YELLOW}[i] Pulando atualização do sistema${NC}"
fi

# Instalar Kali XFCE minimal (se não estiver instalado)
echo -e "${BLUE}[3/15] Verificando instalação Kali XFCE...${NC}"
if ! dpkg -l | grep -q "kali-linux-default"; then
    echo -e "${YELLOW}[i] Instalando Kali XFCE minimal...${NC}"
    echo -e "${YELLOW}[i] Isso pode demorar 15-30 minutos...${NC}"
    DEBIAN_FRONTEND=noninteractive apt install -y kali-linux-default xfce4 xfce4-goodies 2>&1 | grep -E "(Reading|Setting up|Unpacking|Processing)" || {
        echo -e "${YELLOW}[!] Instalação do Kali XFCE pode ter falhado. Continuando...${NC}"
    }
else
    echo -e "${GREEN}[✓] Kali XFCE já está instalado${NC}"
fi

# ============================================================================
# SERVIDORES E PROTOCOLOS
# ============================================================================

echo -e "${BLUE}[4/15] Instalando servidores HTTP e protocolos...${NC}"

# Servidor HTTP simples (Python)
echo -e "${BLUE}[*] Instalando Python3...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y python3 python3-pip 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Servidor HTTP leve (lighttpd)
echo -e "${BLUE}[*] Instalando Lighttpd...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y lighttpd 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# PHP para servidores web
echo -e "${BLUE}[*] Instalando PHP...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y php php-cli php-curl php-mbstring 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Servidor FTP
echo -e "${BLUE}[*] Instalando vsftpd...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y vsftpd 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Servidor SMB
echo -e "${BLUE}[*] Instalando Samba...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y samba samba-common-bin 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# ============================================================================
# REVERSE SHELLS E LISTENERS
# ============================================================================

echo -e "${BLUE}[5/15] Instalando ferramentas de reverse shell...${NC}"

# Netcat (tradicional e OpenBSD)
echo -e "${BLUE}[*] Instalando Netcat...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y netcat-traditional netcat-openbsd nc 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Socat (socket cat - muito útil para pivoting)
echo -e "${BLUE}[*] Instalando Socat...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y socat 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Ncat (versão do Nmap)
echo -e "${BLUE}[*] Instalando Nmap...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y nmap 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Pwncat (netcat melhorado)
echo -e "${BLUE}[*] Instalando Pwncat...${NC}"
pip3 install --quiet pwncat-cs 2>&1 | grep -v "Requirement already satisfied" || true

# ============================================================================
# SSH E RDP
# ============================================================================

echo -e "${BLUE}[6/15] Configurando SSH e RDP...${NC}"

# SSH Server
echo -e "${BLUE}[*] Instalando OpenSSH Server...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y openssh-server 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true
systemctl enable ssh 2>/dev/null || true
systemctl start ssh 2>/dev/null || true

# RDP Server (xrdp)
echo -e "${BLUE}[*] Instalando xrdp...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y xrdp 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true
systemctl enable xrdp 2>/dev/null || true
systemctl start xrdp 2>/dev/null || true

# Configurar SSH para permitir port forwarding
sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config
systemctl restart ssh

# ============================================================================
# TUNNELING E PIVOTING
# ============================================================================

echo -e "${BLUE}[7/15] Instalando ferramentas de tunneling e pivoting...${NC}"

# Chisel (tunneling rápido)
if ! command -v chisel &> /dev/null; then
    echo -e "${YELLOW}[i] Instalando Chisel...${NC}"
    timeout 60 wget --timeout=30 --tries=3 -q https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_amd64.gz -O /tmp/chisel.gz && {
        gunzip /tmp/chisel.gz 2>/dev/null
        mv /tmp/chisel /usr/local/bin/chisel 2>/dev/null
        chmod +x /usr/local/bin/chisel 2>/dev/null
        echo -e "${GREEN}[✓] Chisel instalado${NC}"
    } || {
        echo -e "${YELLOW}[!] Falha ao baixar Chisel. Continuando...${NC}"
    }
else
    echo -e "${GREEN}[✓] Chisel já está instalado${NC}"
fi

# Plink (PuTTY link - tunneling SSH)
echo -e "${BLUE}[*] Instalando Putty-tools...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y putty-tools 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# SSHuttle (VPN via SSH)
echo -e "${BLUE}[*] Instalando SSHuttle...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y sshuttle 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Ngrok (tunneling público)
if ! command -v ngrok &> /dev/null; then
    echo -e "${YELLOW}[i] Instalando Ngrok...${NC}"
    timeout 60 wget --timeout=30 --tries=3 -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O /tmp/ngrok.tgz && {
        tar -xzf /tmp/ngrok.tgz -C /usr/local/bin/ 2>/dev/null
        chmod +x /usr/local/bin/ngrok 2>/dev/null
        echo -e "${GREEN}[✓] Ngrok instalado${NC}"
    } || {
        echo -e "${YELLOW}[!] Falha ao baixar Ngrok. Continuando...${NC}"
        echo -e "${YELLOW}[i] Você pode instalar manualmente depois: https://ngrok.com/download${NC}"
    }
else
    echo -e "${GREEN}[✓] Ngrok já está instalado${NC}"
fi

# Serveo (tunneling via SSH público)
# Já vem com SSH, só precisa de script wrapper

# ============================================================================
# PAYLOAD GENERATION
# ============================================================================

echo -e "${BLUE}[8/15] Instalando geradores de payload...${NC}"

# MSFVenom (já vem com Metasploit)
apt install -y metasploit-framework

# Payloads All The Things (templates)
if [ ! -d "/opt/payloadsallthethings" ]; then
    echo -e "${YELLOW}[i] Baixando PayloadsAllTheThings...${NC}"
    echo -e "${YELLOW}[i] Isso pode demorar alguns minutos...${NC}"
    timeout 300 git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git /opt/payloadsallthethings 2>&1 | grep -E "(Cloning|Receiving|Resolving)" || {
        echo -e "${YELLOW}[!] Falha ao baixar PayloadsAllTheThings. Continuando...${NC}"
    }
else
    echo -e "${GREEN}[✓] PayloadsAllTheThings já existe${NC}"
fi

# Shellter (dynamic shellcode injection)
echo -e "${BLUE}[*] Instalando Shellter...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y shellter 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# ============================================================================
# C2 FRAMEWORKS LEVES
# ============================================================================

echo -e "${BLUE}[9/15] Instalando C2 frameworks leves...${NC}"

# Sliver (C2 moderno e leve)
if ! command -v sliver-server &> /dev/null; then
    echo -e "${YELLOW}[i] Instalando Sliver C2...${NC}"
    echo -e "${YELLOW}[i] Isso pode demorar 5-10 minutos...${NC}"
    timeout 600 bash -c "$(timeout 30 curl -s https://sliver.sh/install)" 2>&1 | grep -E "(Downloading|Installing|sliver)" || {
        echo -e "${YELLOW}[!] Falha ao instalar Sliver. Continuando...${NC}"
        echo -e "${YELLOW}[i] Você pode instalar manualmente depois: https://github.com/BishopFox/sliver${NC}"
    }
else
    echo -e "${GREEN}[✓] Sliver já está instalado${NC}"
fi

# PoshC2 (PowerShell C2)
if [ ! -d "/opt/PoshC2" ]; then
    echo -e "${YELLOW}[i] Instalando PoshC2...${NC}"
    echo -e "${YELLOW}[i] Isso pode demorar alguns minutos...${NC}"
    timeout 300 git clone --depth 1 https://github.com/nettitude/PoshC2.git /opt/PoshC2 2>&1 | grep -E "(Cloning|Receiving|Resolving)" && {
        cd /opt/PoshC2
        timeout 300 ./Install.sh 2>&1 | grep -E "(Installing|Downloading|pip)" || {
            echo -e "${YELLOW}[!] Falha na instalação do PoshC2. Continuando...${NC}"
        }
    } || {
        echo -e "${YELLOW}[!] Falha ao baixar PoshC2. Continuando...${NC}"
    }
else
    echo -e "${GREEN}[✓] PoshC2 já existe${NC}"
fi

# ============================================================================
# FERRAMENTAS DE STEALTH (LOW AND SLOW)
# ============================================================================

echo -e "${BLUE}[10/15] Instalando ferramentas de stealth...${NC}"

# Slowloris (DDoS lento - para testes)
# Já está em Kali/Ferramentas/DDos

# Nmap com timing lento (já instalado)
# Usar: nmap -T1 ou -T2

# Masscan (rápido mas configurável)
echo -e "${BLUE}[*] Instalando Masscan...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y masscan 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# ============================================================================
# COLETA PASSIVA E MONITORAMENTO
# ============================================================================

echo -e "${BLUE}[11/15] Instalando ferramentas de coleta passiva...${NC}"

# Tcpdump
echo -e "${BLUE}[*] Instalando Tcpdump...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y tcpdump 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Wireshark (modo CLI)
echo -e "${BLUE}[*] Instalando Tshark...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y tshark wireshark-common 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Responder (LLMNR/NBT-NS poisoning)
echo -e "${BLUE}[*] Instalando Responder...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y responder 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# Bettercap (man-in-the-middle)
echo -e "${BLUE}[*] Instalando Bettercap...${NC}"
DEBIAN_FRONTEND=noninteractive apt install -y bettercap 2>&1 | grep -E "(Reading|Setting up|Unpacking)" || true

# ============================================================================
# PHISHING SIMPLES
# ============================================================================

echo -e "${BLUE}[12/15] Configurando ferramentas de phishing...${NC}"

# Gophish (phishing framework)
if [ ! -d "/opt/gophish" ]; then
    echo -e "${YELLOW}[i] Baixando Gophish...${NC}"
    timeout 120 wget --timeout=30 --tries=3 -q https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip -O /tmp/gophish.zip && {
        unzip -q /tmp/gophish.zip -d /opt/gophish 2>/dev/null
        chmod +x /opt/gophish/gophish 2>/dev/null
        echo -e "${GREEN}[✓] Gophish instalado${NC}"
    } || {
        echo -e "${YELLOW}[!] Falha ao baixar Gophish. Continuando...${NC}"
    }
else
    echo -e "${GREEN}[✓] Gophish já existe${NC}"
fi

# ============================================================================
# SCRIPTS AUXILIARES
# ============================================================================

echo -e "${BLUE}[13/15] Criando scripts auxiliares...${NC}"

# Script: Iniciar servidor HTTP simples
cat > "$NB1_SCRIPTS/start_http.sh" << 'EOF'
#!/bin/bash
PORT=${1:-8080}
echo "[*] Iniciando servidor HTTP na porta $PORT"
echo "[*] Acesse: http://$(hostname -I | awk '{print $1}'):$PORT"
cd /opt/notebook1/www
python3 -m http.server $PORT
EOF
chmod +x "$NB1_SCRIPTS/start_http.sh"

# Script: Listener Netcat
cat > "$NB1_SCRIPTS/nc_listener.sh" << 'EOF'
#!/bin/bash
PORT=${1:-4444}
echo "[*] Aguardando conexão na porta $PORT..."
nc -lvnp $PORT
EOF
chmod +x "$NB1_SCRIPTS/nc_listener.sh"

# Script: Listener Socat
cat > "$NB1_SCRIPTS/socat_listener.sh" << 'EOF'
#!/bin/bash
PORT=${1:-4444}
echo "[*] Aguardando conexão Socat na porta $PORT..."
socat TCP-LISTEN:$PORT,fork,reuseaddr EXEC:/bin/bash
EOF
chmod +x "$NB1_SCRIPTS/socat_listener.sh"

# Script: Chisel Server
cat > "$NB1_SCRIPTS/chisel_server.sh" << 'EOF'
#!/bin/bash
PORT=${1:-8000}
echo "[*] Iniciando Chisel server na porta $PORT..."
chisel server --port $PORT --reverse
EOF
chmod +x "$NB1_SCRIPTS/chisel_server.sh"

# Script: Ngrok tunnel
cat > "$NB1_SCRIPTS/ngrok_tunnel.sh" << 'EOF'
#!/bin/bash
PORT=${1:-8080}
PROTOCOL=${2:-http}
echo "[*] Criando túnel Ngrok para porta $PORT ($PROTOCOL)..."
ngrok $PROTOCOL $PORT
EOF
chmod +x "$NB1_SCRIPTS/ngrok_tunnel.sh"

# Script: Serveo tunnel (via SSH)
cat > "$NB1_SCRIPTS/serveo_tunnel.sh" << 'EOF'
#!/bin/bash
PORT=${1:-8080}
echo "[*] Criando túnel Serveo para porta $PORT..."
ssh -R 80:localhost:$PORT serveo.net
EOF
chmod +x "$NB1_SCRIPTS/serveo_tunnel.sh"

# Script: Iniciar Sliver
cat > "$NB1_SCRIPTS/start_sliver.sh" << 'EOF'
#!/bin/bash
echo "[*] Iniciando Sliver C2..."
sliver-server
EOF
chmod +x "$NB1_SCRIPTS/start_sliver.sh"

# Script: Iniciar PoshC2
cat > "$NB1_SCRIPTS/start_poshc2.sh" << 'EOF'
#!/bin/bash
echo "[*] Iniciando PoshC2..."
cd /opt/PoshC2
python3 PoshC2.py
EOF
chmod +x "$NB1_SCRIPTS/start_poshc2.sh"

# Script: Scan lento (stealth)
cat > "$NB1_SCRIPTS/stealth_scan.sh" << 'EOF'
#!/bin/bash
TARGET=${1:-192.168.1.0/24}
echo "[*] Scan stealth lento (-T1) em $TARGET..."
nmap -T1 -sS -Pn $TARGET
EOF
chmod +x "$NB1_SCRIPTS/stealth_scan.sh"

# Script: Monitorar tráfego
cat > "$NB1_SCRIPTS/monitor_traffic.sh" << 'EOF'
#!/bin/bash
INTERFACE=${1:-eth0}
echo "[*] Monitorando tráfego em $INTERFACE..."
tcpdump -i $INTERFACE -n -v
EOF
chmod +x "$NB1_SCRIPTS/monitor_traffic.sh"

# Criar aliases úteis
cat > /etc/profile.d/notebook1-aliases.sh << 'EOF'
# Notebook 1 - Aliases úteis
alias nb1-http='/opt/notebook1/scripts/start_http.sh'
alias nb1-nc='/opt/notebook1/scripts/nc_listener.sh'
alias nb1-socat='/opt/notebook1/scripts/socat_listener.sh'
alias nb1-chisel='/opt/notebook1/scripts/chisel_server.sh'
alias nb1-ngrok='/opt/notebook1/scripts/ngrok_tunnel.sh'
alias nb1-serveo='/opt/notebook1/scripts/serveo_tunnel.sh'
alias nb1-scan='/opt/notebook1/scripts/stealth_scan.sh'
alias nb1-monitor='/opt/notebook1/scripts/monitor_traffic.sh'
alias nb1-payloads='cd /opt/notebook1/payloads'
alias nb1-www='cd /opt/notebook1/www'
EOF

# ============================================================================
# CONFIGURAÇÕES DE SEGURANÇA E STEALTH
# ============================================================================

echo -e "${BLUE}[14/15] Aplicando configurações de stealth...${NC}"

# Desabilitar logs desnecessários (reduzir assinatura)
sed -i 's/#ForwardToSyslog=yes/ForwardToSyslog=no/' /etc/systemd/journald.conf 2>/dev/null

# Configurar hostname genérico
CURRENT_HOSTNAME=$(hostname)
if [[ "$CURRENT_HOSTNAME" == *"kali"* ]] || [[ "$CURRENT_HOSTNAME" == *"notebook"* ]]; then
    NEW_HOSTNAME="workstation-$(shuf -i 1000-9999 -n 1)"
    hostnamectl set-hostname "$NEW_HOSTNAME"
    echo -e "${YELLOW}[i] Hostname alterado para: $NEW_HOSTNAME${NC}"
fi

# Configurar timezone genérico (não revelar localização)
timedatectl set-timezone UTC

# ============================================================================
# CONFIGURAR SERVIÇOS
# ============================================================================

echo -e "${BLUE}[15/15] Configurando serviços...${NC}"

# Lighttpd (servidor web leve)
systemctl enable lighttpd
systemctl start lighttpd

# Configurar lighttpd para servir arquivos
cat > /etc/lighttpd/lighttpd.conf << 'LIGHTTPD_EOF'
server.modules = (
    "mod_access",
    "mod_alias",
    "mod_compress",
    "mod_redirect",
    "mod_rewrite"
)

server.document-root        = "/opt/notebook1/www"
server.upload-dirs          = ( "/opt/notebook1/www/uploads" )
server.errorlog             = "/opt/notebook1/logs/lighttpd-error.log"
server.pid-file             = "/var/run/lighttpd.pid"
server.username             = "www-data"
server.groupname            = "www-data"
server.port                 = 80

index-file.names            = ( "index.php", "index.html", "index.lighttpd.html" )
url.access-deny             = ( "~", ".inc" )
static-file.exclude-extensions = ( ".php", ".pl", ".fcgi" )

compress.cache-dir          = "/var/cache/lighttpd/compress/"
compress.filetype           = ( "application/javascript", "text/css", "text/html", "text/plain" )
LIGHTTPD_EOF

systemctl restart lighttpd

# Samba (compartilhamento SMB)
cat > /etc/samba/smb.conf << 'SAMBA_EOF'
[global]
   workgroup = WORKGROUP
   server string = File Server
   security = user
   map to guest = Bad User

[payloads]
   comment = Payloads Directory
   path = /opt/notebook1/payloads
   browseable = yes
   writable = yes
   guest ok = yes
   create mask = 0664
   directory mask = 0775
SAMBA_EOF

systemctl enable smbd
systemctl restart smbd

# ============================================================================
# FINALIZAÇÃO
# ============================================================================

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}              INSTALAÇÃO CONCLUÍDA!                        ${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}Diretórios criados:${NC}"
echo -e "  ${GREEN}Payloads:${NC} $NB1_PAYLOADS"
echo -e "  ${GREEN}WWW:${NC} $NB1_WWW"
echo -e "  ${GREEN}Scripts:${NC} $NB1_SCRIPTS"
echo -e "  ${GREEN}Logs:${NC} $NB1_LOGS"
echo ""

echo -e "${CYAN}Scripts disponíveis:${NC}"
echo -e "  ${GREEN}nb1-http${NC}      - Iniciar servidor HTTP"
echo -e "  ${GREEN}nb1-nc${NC}        - Listener Netcat"
echo -e "  ${GREEN}nb1-socat${NC}     - Listener Socat"
echo -e "  ${GREEN}nb1-chisel${NC}    - Servidor Chisel"
echo -e "  ${GREEN}nb1-ngrok${NC}     - Túnel Ngrok"
echo -e "  ${GREEN}nb1-serveo${NC}    - Túnel Serveo"
echo -e "  ${GREEN}nb1-scan${NC}      - Scan stealth"
echo -e "  ${GREEN}nb1-monitor${NC}   - Monitorar tráfego"
echo ""

echo -e "${CYAN}Serviços ativos:${NC}"
echo -e "  ${GREEN}SSH:${NC} $(systemctl is-active ssh)"
echo -e "  ${GREEN}RDP:${NC} $(systemctl is-active xrdp)"
echo -e "  ${GREEN}HTTP:${NC} $(systemctl is-active lighttpd)"
echo -e "  ${GREEN}SMB:${NC} $(systemctl is-active smbd)"
echo ""

echo -e "${YELLOW}[!] IMPORTANTE:${NC}"
echo -e "  1. Configure senhas SSH e RDP: ${GREEN}passwd${NC}"
echo -e "  2. Configure Ngrok (se usar): ${GREEN}ngrok config add-authtoken <token>${NC}"
echo -e "  3. Leia o guia completo: ${GREEN}NOTEBOOK1-GUIDE.md${NC}"
echo ""

echo -e "${GREEN}Notebook 1 configurado como Stealth Box!${NC}"
echo ""

