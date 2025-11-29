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

# Atualizar sistema
echo -e "${BLUE}[2/15] Atualizando sistema...${NC}"
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1

# Instalar Kali XFCE minimal (se não estiver instalado)
echo -e "${BLUE}[3/15] Verificando instalação Kali XFCE...${NC}"
if ! dpkg -l | grep -q "kali-linux-default"; then
    echo -e "${YELLOW}[i] Instalando Kali XFCE minimal...${NC}"
    apt install -y kali-linux-default xfce4 xfce4-goodies
fi

# ============================================================================
# SERVIDORES E PROTOCOLOS
# ============================================================================

echo -e "${BLUE}[4/15] Instalando servidores HTTP e protocolos...${NC}"

# Servidor HTTP simples (Python)
apt install -y python3 python3-pip

# Servidor HTTP leve (lighttpd)
apt install -y lighttpd

# PHP para servidores web
apt install -y php php-cli php-curl php-mbstring

# Servidor FTP
apt install -y vsftpd

# Servidor SMB
apt install -y samba samba-common-bin

# ============================================================================
# REVERSE SHELLS E LISTENERS
# ============================================================================

echo -e "${BLUE}[5/15] Instalando ferramentas de reverse shell...${NC}"

# Netcat (tradicional e OpenBSD)
apt install -y netcat-traditional netcat-openbsd nc

# Socat (socket cat - muito útil para pivoting)
apt install -y socat

# Ncat (versão do Nmap)
apt install -y nmap

# Pwncat (netcat melhorado)
pip3 install pwncat-cs > /dev/null 2>&1

# ============================================================================
# SSH E RDP
# ============================================================================

echo -e "${BLUE}[6/15] Configurando SSH e RDP...${NC}"

# SSH Server
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh

# RDP Server (xrdp)
apt install -y xrdp
systemctl enable xrdp
systemctl start xrdp

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
    wget -q https://github.com/jpillora/chisel/releases/download/v1.9.1/chisel_1.9.1_linux_amd64.gz -O /tmp/chisel.gz
    gunzip /tmp/chisel.gz
    mv /tmp/chisel /usr/local/bin/chisel
    chmod +x /usr/local/bin/chisel
fi

# Plink (PuTTY link - tunneling SSH)
apt install -y putty-tools

# SSHuttle (VPN via SSH)
apt install -y sshuttle

# Ngrok (tunneling público)
if ! command -v ngrok &> /dev/null; then
    echo -e "${YELLOW}[i] Instalando Ngrok...${NC}"
    wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O /tmp/ngrok.tgz
    tar -xzf /tmp/ngrok.tgz -C /usr/local/bin/
    chmod +x /usr/local/bin/ngrok
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
    git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git /opt/payloadsallthethings
fi

# Shellter (dynamic shellcode injection)
apt install -y shellter

# ============================================================================
# C2 FRAMEWORKS LEVES
# ============================================================================

echo -e "${BLUE}[9/15] Instalando C2 frameworks leves...${NC}"

# Sliver (C2 moderno e leve)
if ! command -v sliver-server &> /dev/null; then
    echo -e "${YELLOW}[i] Instalando Sliver C2...${NC}"
    curl https://sliver.sh/install | bash
fi

# PoshC2 (PowerShell C2)
if [ ! -d "/opt/PoshC2" ]; then
    echo -e "${YELLOW}[i] Instalando PoshC2...${NC}"
    git clone --depth 1 https://github.com/nettitude/PoshC2.git /opt/PoshC2
    cd /opt/PoshC2
    ./Install.sh > /dev/null 2>&1
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
apt install -y masscan

# ============================================================================
# COLETA PASSIVA E MONITORAMENTO
# ============================================================================

echo -e "${BLUE}[11/15] Instalando ferramentas de coleta passiva...${NC}"

# Tcpdump
apt install -y tcpdump

# Wireshark (modo CLI)
apt install -y tshark wireshark-common

# Tshark (já vem com Wireshark)

# Responder (LLMNR/NBT-NS poisoning)
apt install -y responder

# Bettercap (man-in-the-middle)
apt install -y bettercap

# ============================================================================
# PHISHING SIMPLES
# ============================================================================

echo -e "${BLUE}[12/15] Configurando ferramentas de phishing...${NC}"

# Gophish (phishing framework)
if [ ! -d "/opt/gophish" ]; then
    echo -e "${YELLOW}[i] Baixando Gophish...${NC}"
    wget -q https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip -O /tmp/gophish.zip
    unzip -q /tmp/gophish.zip -d /opt/gophish
    chmod +x /opt/gophish/gophish
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

