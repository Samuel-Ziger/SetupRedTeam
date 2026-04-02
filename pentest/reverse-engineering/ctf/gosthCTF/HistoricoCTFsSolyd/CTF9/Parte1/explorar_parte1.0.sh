#!/bin/bash
#
# Explora o servidor da Parte 1 (CTF9) e salva tudo em um único arquivo.
# Não usa 'ip' nem 'arp' — só alternativas (/proc, etc.).

OUTFILE="exploracao_$(date +%Y%m%d_%H%M%S).txt"

exec 2>>"$OUTFILE"

log() { echo "[*] $1" | tee -a "$OUTFILE"; }
sec() { echo -e "\n\n==================== $1 ====================\n" | tee -a "$OUTFILE"; }

log "Salvando resultados em: $OUTFILE"
sec "Início: $(date)"

# --- 1. Rede e hosts ---
sec "1. Rede e hosts"
{
echo "--- /etc/hosts ---"
cat /etc/hosts 2>/dev/null

echo -e "\n--- /proc/net/dev ---"
cat /proc/net/dev 2>/dev/null

echo -e "\n--- /sys/class/net ---"
ls /sys/class/net/ 2>/dev/null

echo -e "\n--- hostname -I ---"
hostname -I 2>/dev/null

echo -e "\n--- /proc/net/route ---"
cat /proc/net/route 2>/dev/null

echo -e "\n--- /etc/resolv.conf ---"
cat /etc/resolv.conf 2>/dev/null

echo -e "\n--- /proc/net/tcp ---"
cat /proc/net/tcp 2>/dev/null

echo -e "\n--- /proc/net/udp ---"
cat /proc/net/udp 2>/dev/null

echo -e "\n--- /proc/net/arp ---"
cat /proc/net/arp 2>/dev/null
} >> "$OUTFILE"

# --- 2. Apache ---
sec "2. Apache"
{
echo "--- sites-enabled (ls) ---"
ls -la /etc/apache2/sites-enabled/ 2>/dev/null

echo -e "\n--- sites-enabled (conteúdo) ---"
for f in /etc/apache2/sites-enabled/*; do
[ -f "$f" ] && echo ">> $f" && cat "$f"
done

echo -e "\n--- grep ProxyPass|Redirect|ServerName|ServerAlias ---"
grep -r "ProxyPass\|Redirect\|ServerName\|ServerAlias" /etc/apache2/ 2>/dev/null

echo -e "\n--- apache2.conf (primeiras 80 linhas) ---"
head -80 /etc/apache2/apache2.conf 2>/dev/null
} >> "$OUTFILE"

# --- 3. Aplicação ---
sec "3. Aplicação"
{
echo "--- test.php ---"
cat /var/www/blogo/test.php 2>/dev/null

echo -e "\n--- noticias.php (primeiras 200 linhas) ---"
head -200 /var/www/blogo/noticias.php 2>/dev/null

echo -e "\n--- index.html ---"
head -100 /var/www/blogo/index.html 2>/dev/null

echo -e "\n--- files/ ---"
ls -la /var/www/blogo/files/ 2>/dev/null
} >> "$OUTFILE"

# --- 4. Logs Apache ---
sec "4. Logs Apache"
{
echo "--- access.log (últimas 100) ---"
tail -100 /var/log/apache2/access.log 2>/dev/null

echo -e "\n--- error.log (últimas 50) ---"
tail -50 /var/log/apache2/error.log 2>/dev/null

echo -e "\n--- grep projects-blogo|10.0.|internal ---"
grep -E "projects-blogo|10\.0\.|internal" /var/log/apache2/access.log 2>/dev/null
} >> "$OUTFILE"

# --- 5. Cron e systemd ---
sec "5. Cron e systemd"
{
echo "--- /etc/cron.d ---"
ls -la /etc/cron.d/ 2>/dev/null
cat /etc/cron.d/* 2>/dev/null

echo -e "\n--- cron.daily / cron.hourly ---"
ls -la /etc/cron.daily/ /etc/cron.hourly/ 2>/dev/null

echo -e "\n--- crontab root ---"
crontab -l -u root 2>/dev/null

echo -e "\n--- crontab adalberto ---"
crontab -l -u adalberto 2>/dev/null

echo -e "\n--- crontab www-data ---"
crontab -l -u www-data 2>/dev/null

echo -e "\n--- systemctl services ---"
systemctl list-units --type=service 2>/dev/null
} >> "$OUTFILE"

# --- 6. Home usuários ---
sec "6. Home usuários"
{
echo "--- adalberto .bash_history ---"
cat /home/adalberto/.bash_history 2>/dev/null

echo -e "\n--- adalberto .ssh ---"
ls -la /home/adalberto/.ssh/ 2>/dev/null

echo -e "\n--- ubuntu home ---"
ls -la /home/ubuntu/ 2>/dev/null

echo -e "\n--- ubuntu .bash_history ---"
cat /home/ubuntu/.bash_history 2>/dev/null
} >> "$OUTFILE"

# --- 7. MySQL ---
sec "7. MySQL"
{
mysql --protocol=TCP -h 127.0.0.1 -u blogodb -p'WPcmqw16ZmzO!5paSC4' -e "
SHOW VARIABLES LIKE '%hostname%';
SHOW VARIABLES LIKE '%datadir%';
SELECT * FROM information_schema.SCHEMATA;
SELECT table_schema, table_name FROM information_schema.TABLES LIMIT 50;
" 2>/dev/null || echo "(mysql falhou ou não disponível)"
} >> "$OUTFILE"

# --- 8. Processos ---
sec "8. Processos e env"
{
echo "--- ps auxeww ---"
ps auxeww | head -80

echo -e "\n--- Apache environ ---"
APID=$(pgrep -f apache2 | head -1)

if [ -n "$APID" ]; then
cat /proc/$APID/environ | tr '\0' '\n'
else
echo "nenhum apache encontrado"
fi
} >> "$OUTFILE"

# --- 9. Logs extras ---
sec "9. Logs below e outros"
{
ls -la /var/log/below/ 2>/dev/null
cat /var/log/below/* 2>/dev/null

echo -e "\n--- /var/log ---"
ls -la /var/log/

echo -e "\n--- grep rede interna ---"
grep -r "10\.0\.\|internal\|blogo" /var/log/*.log 2>/dev/null | head -50
} >> "$OUTFILE"

# --- 10. Grep configs ---
sec "10. Grep configs"
{
grep -ri "host\|url\|proxy\|internal\|10\.0\.\|blogo" /etc/apache2/ /var/www/blogo/ 2>/dev/null
} >> "$OUTFILE"

sec "Fim"
echo "Finalizado: $(date)" >> "$OUTFILE"

log "Concluído"
echo "Arquivo gerado:"
echo "$OUTFILE"
