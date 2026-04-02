# Análise do que foi coletado com o script (root na Parte 1)

## O que está muito bom

- **Rede:** IPs (10.0.55.149, 172.17.0.1), interfaces (ens5, docker0), rotas, ARP (10.0.0.1, 10.0.0.2), `/proc/net/tcp` e `udp`, `resolv.conf` (ec2.internal). Suficiente para entender a rede e usar o host como pivô na Parte 2.
- **Apache:** VirtualHost, DocumentRoot, `Require local` em `/var/www/blogo/files`, módulos. Bom para documentar e para procurar proxy/vhosts na Parte 2.
- **Aplicação:** `test.php` (reverse shell 192.168.89.152:4444), LFI em `noticias.php`, flag em comentário, conteúdo de `files/` (settings.json, test.php, test.txt). Tudo que precisa para reproduzir o ataque da Parte 1.
- **Logs Apache:** access.log e error.log com IPs (179.54.x, 18.234.199.154), uso de shell.php/rev.php, ngrok, cliente 172.17.0.1 (host Docker). Muito útil para linha do tempo e para ver “quem mais” acessou.
- **Processos (`ps auxeww`):** Apache, MySQL, shells reversas (ngrok), `su adalberto`, exploit CVE, `below record`, `su 0xdtc`, `explorar_parte1.0.sh`. Mostra exatamente o que estava rodando no momento da coleta.
- **Below / exploit:** Symlink `error_root.log` → `/etc/passwd` e conteúdo de `/etc/passwd` com o usuário `0xdtc` — prova que a escalação para root funcionou.
- **MySQL:** hostname `ip-10-0-55-149`, datadir, listagem de tabelas do information_schema. Confirma que o MySQL é local.
- **Config da aplicação:** `config.php` com host 127.0.0.1, DB `blogodb`, usuário `blogodb`; `settings.json` com username `blogodb`. Falta só a **senha** do MySQL (linha `password` do config) se o script não tiver feito `cat` completo do `config.php`.
- **Contato TI:** `ti@blogo.sy` no noticias.php — pode ser útil em phishing ou Parte 2.
- **Domínio:** `blogo.sy` e menção a `ftpmaster.internal` no bootstrap.log (build; pode não ser rede viva, mas é anotado).

## O que complementar (se for rodar de novo)

1. **Senha do MySQL:**  
   `cat /var/www/blogo/config/config.php` (ou só a linha com `password`) e anotar.
2. **AWS (para Parte 2):**  
   Se for EC2, no host (ou no container, se tiver rota):  
   `curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/` e depois o JSON da role. Assim você tem credenciais para S3/EC2/Secrets na Parte 2.
3. **SSH / authorized_keys:**  
   `cat /root/.ssh/authorized_keys` e `ls -la /root/.ssh/` (e o mesmo para `/home/ubuntu/.ssh/` se existir). Útil para ver se há chaves de outros servidores/pivô.
4. **Conexões ativas legíveis:**  
   `ss -tunap` ou `netstat -tunap` — fica mais fácil de ler que só `/proc/net/tcp` em hex para ver conexões com outros IPs internos.

## Resumo para a Parte 2

| Item              | Valor / onde está na coleta |
|-------------------|-----------------------------|
| IP interno        | 10.0.55.149                 |
| Rede Docker       | 172.17.0.1                  |
| Gateway / vizinhos (ARP) | 10.0.0.1, 10.0.0.2   |
| Hostname          | ip-10-0-55-149              |
| DB local          | blogodb, user blogodb (senha em config.php) |
| Contato           | ti@blogo.sy                 |
| Domínio           | blogo.sy                    |

Conclusão: a coleta está **muito boa** para documentar a Parte 1 e para usar como base na Parte 2 (rede interna, pivô, credenciais locais). Só vale fechar a senha do MySQL e, se o alvo for EC2, puxar o metadata da AWS; o resto já cobre rede, serviços, exploit e aplicação.
