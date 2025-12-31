#!/bin/bash
echo "=== AnonCheck - Verificação do Sistema ==="
echo ""

SCORE=100
DICAS=()

# Verifica VPN
if ifconfig | grep -q "tun0"; then
  echo "[+] VPN detectada (tun0)"
else
  echo "[-] VPN não detectada (tun0 ausente)"
  SCORE=$((SCORE - 30))
  DICAS+=("Ative uma VPN confiável para proteger sua conexão.")
fi

# Verifica TOR
if pgrep -x "tor" > /dev/null; then
  echo "[+] Processo do TOR ativo"
else
  echo "[-] TOR não está rodando"
  SCORE=$((SCORE - 30))
  DICAS+=("Considere utilizar o TOR para maior anonimato.")
fi

# Verifica DNS
echo ""
echo "Verificando servidores DNS em uso:"
if [ -f /etc/resolv.conf ]; then
  cat /etc/resolv.conf | grep "nameserver"
  if grep -Eq "192\.168|10\.|172\." /etc/resolv.conf; then
    echo "[-] DNS local detectado — possível DNS leak."
    SCORE=$((SCORE - 20))
    DICAS+=("Configure um servidor DNS confiável como 1.1.1.1 (Cloudflare) ou 9.9.9.9 (Quad9).")
  else
    echo "[+] Servidor DNS público detectado"
  fi
else
  echo "Arquivo /etc/resolv.conf não encontrado"
fi

# Conexões de rede ativas
echo ""
echo "Conexões de rede com processos:"
lsof -i -P -n | grep ESTABLISHED || echo "Sem conexões detectadas"

# Processos de rede
echo ""
echo "Processos ativos com rede:"
netstat -tunlp 2>/dev/null || echo "netstat não disponível"

# Mostrar dicas
echo ""
if [ ${#DICAS[@]} -gt 0 ]; then
  echo "Dicas para melhorar seu anonimato:"
  for dica in "${DICAS[@]}"; do
    echo "- $dica"
  done
else
  echo "Nenhuma recomendação. Seu sistema parece bem anonimizado."
fi

# Score
echo ""
echo "Score de anonimato do sistema: $SCORE/100"
