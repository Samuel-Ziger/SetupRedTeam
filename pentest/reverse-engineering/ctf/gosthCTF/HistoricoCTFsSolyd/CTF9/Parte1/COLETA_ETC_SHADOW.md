# Coleta adicional: /etc e shadow

## O que você trouxe

### 1. /etc/shadow (útil)

- **adalberto** tem hash de senha (yescrypt, `$y$j9T$...`):
  ```
  adalberto:$y$j9T$r3wnOtEWlLzj4rWu/WzOB1$mUVwpDmeCFN04QSxhrZVZ2wt0PuXP9THK.K0.IOW6u6:20469:0:99999:7:::
  ```
- **ubuntu:** `!` (conta bloqueada).
- **mysql:** `!` (conta bloqueada).
- Resto: contas de sistema com `*` ou `!` (sem senha / bloqueadas).

**Para a Parte 2:** Se aparecer outro Linux com o mesmo usuário (ex.: adalberto) ou política de senhas parecida, você já tem a senha em claro (WPcmqw16ZmzO!5paSC4). O hash serve para: (1) documentar no relatório; (2) tentar reutilizar a mesma senha noutros serviços/servidores; (3) comparar se algum outro shadow tiver o mesmo hash (mesma senha).

---

### 2. /etc — estrutura

- **passwd** estava **-rw-rw-rw-** (1350 bytes) — estado após o exploit CVE (0666 aplicado pelo below).
- **hostname:** ip-10-0-55-149.
- **networks:** só `link-local 169.254.0.0` — sem redes internas extras.
- Pastas relevantes: apache2, mysql, php, cron.d, sudoers.d, pam.d, ssl, ca-certificates.

Se quiser documentar o sudo do adalberto na Parte 1, no servidor pode rodar:
```bash
cat /etc/sudoers
ls -la /etc/sudoers.d/
cat /etc/sudoers.d/*
```
Assim fica registrado que ele só tem permissão para o `below`.

---

### 3. Resto

- Listagem de `/` e `/etc`: boa para ter mapa do sistema (apache2, mysql, php, cloud, apparmor.d, etc.); nada de sensível além do shadow.
- **/etc/networks** e **hostname** já estavam cobertos na coleta anterior.

---

## Resumo

| Item        | Valor / uso |
|------------|-------------|
| Hash adalberto | yescrypt; senha conhecida: WPcmqw16ZmzO!5paSC4 |
| Uso na Parte 2 | Reutilizar senha noutros alvos; documentar no relatório |
| /etc/sudoers   | Se quiser: `cat /etc/sudoers` e `sudoers.d/*` para provar sudo restrito ao below |

Guarde o hash do adalberto (e a senha) na sua lista de credenciais da Parte 1 para testar na Parte 2.
