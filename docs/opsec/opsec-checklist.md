# 🔒 OPSEC Checklist - Segurança Operacional

## 📋 Checklist Pré-Engagement

Use este checklist **ANTES** de iniciar qualquer operação de pentest/red team.

---

## ✅ **ESSENCIAIS** (Críticos - Nunca pule)

### **1. VPN/Proxy Ativo**
```bash
# Verificar IP público
curl ifconfig.me

# Ou usar script OPSEC
source lib/opsec.sh
check_vpn
```

- [ ] VPN conectada e funcional
- [ ] IP público **NÃO** é seu IP real
- [ ] IP pertence ao provedor VPN esperado
- [ ] Killswitch configurado

**❌ Risco de pular:** Exposição do seu IP real, rastreamento direto.

---

### **2. DNS Leak Protection**
```bash
# Verificar servidor DNS
nslookup google.com

# Ou usar script OPSEC
source lib/opsec.sh
check_dns_leak
```

- [ ] DNS **NÃO** é do seu provedor local
- [ ] DNS é do VPN ou servidor confiável
- [ ] Teste em: https://dnsleaktest.com

**❌ Risco de pular:** DNS revela localização e provedor real.

---

### **3. User-Agent Rotation**
```bash
# Usar User-Agent aleatório
UA=$(source lib/opsec.sh && random_user_agent)
curl -A "$UA" https://target.com
```

- [ ] Scripts usam User-Agents variados
- [ ] Não usar ferramentas com UA padrão (ex: "Python-requests")
- [ ] Simular navegadores reais

**❌ Risco de pular:** Fácil detecção via fingerprinting de UA.

---

### **4. Rate Limiting**
```bash
# Delay entre requests
source lib/opsec.sh
rate_limit 2 5  # 2-5 segundos aleatório
```

- [ ] Delays configurados entre requests
- [ ] Scans em modo `-T2` ou `-T3` (nunca `-T5`)
- [ ] Evitar milhares de requests por segundo

**❌ Risco de pular:** Bloqueio por WAF/IPS, rate limiting, banimento de IP.

---

### **5. Autorização Documentada**
- [ ] Contrato de pentest assinado
- [ ] Escopo de IPs/domínios aprovado por escrito
- [ ] Janela de tempo de teste definida
- [ ] Contato de emergência do cliente

**❌ Risco de pular:** Processo criminal por invasão não autorizada.

---

## ⚠️ **IMPORTANTES** (Recomendados - Pule com cautela)

### **6. Logging Local**
```bash
# Salvar todos os comandos
script -a /var/log/pentest_$(date +%Y%m%d).log
```

- [ ] Logs de comandos habilitados
- [ ] Capturas de tela de achados importantes
- [ ] Timestamps em todas as ações

**❌ Risco de pular:** Sem evidências para relatório, difícil reproduzir achados.

---

### **7. Verificação de Recursos**
```bash
# Verificar sistema antes de scan pesado
source lib/resource_check.sh
full_system_check
```

- [ ] RAM suficiente para operação
- [ ] Espaço em disco >10GB livre
- [ ] CPU não sobrecarregada

**❌ Risco de pular:** Crash durante scan, perda de dados, sistema travado.

---

### **8. Backup de Dados**
```bash
# Backup antes de engagement
source lib/backup_tools.sh
backup_custom_scripts
```

- [ ] Backup de ferramentas críticas
- [ ] Backup de scripts customizados
- [ ] Código commitado no Git

**❌ Risco de pular:** Perda de ferramentas/dados se sistema falhar.

---

### **9. Sanitização de Input**
```bash
# Sempre validar input de usuário
target=$(sanitize_input "$1")
validate_target "$target"
```

- [ ] Inputs validados antes de uso
- [ ] Proteção contra command injection
- [ ] Verificação de formato de IPs/domínios

**❌ Risco de pular:** Vulnerabilidade nos seus próprios scripts.

---

### **10. Anonimização de Metadados**
```bash
# Remover metadados de arquivos
exiftool -all= relatorio.pdf
```

- [ ] Metadados removidos de PDFs/imagens
- [ ] Nome real não aparece em arquivos
- [ ] Caminhos de diretórios sanitizados

**❌ Risco de pular:** Vazamento de informações pessoais.

---

## 💡 **BOAS PRÁTICAS** (Opcionais - Profissionalismo)

### **11. Multi-Hop VPN**
```bash
# Cadeia de VPNs
VPN1 → VPN2 → Target
```

- [ ] Usar 2+ VPNs em cadeia
- [ ] VPNs de provedores diferentes
- [ ] Países diferentes

**Benefício:** Camada extra de anonimato.

---

### **12. Tor para Reconnaissance Passivo**
```bash
# Reconnaissance via Tor
proxychains nmap -sT target.com
```

- [ ] OSINT via Tor
- [ ] Scans passivos via Tor
- [ ] Nunca scans ativos (muito lento)

**Benefício:** Anonimato em buscas públicas.

---

### **13. Burner Infrastructure**
```bash
# VPS descartável para C2
```

- [ ] VPS temporário para C2
- [ ] Domínios descartáveis
- [ ] Email burner para registros

**Benefício:** Infraestrutura descartável pós-engagement.

---

### **14. Encrypted Communications**
```bash
# Comunicação criptografada com cliente
```

- [ ] PGP para emails sensíveis
- [ ] Signal/Element para mensagens
- [ ] NUNCA WhatsApp/SMS para dados críticos

**Benefício:** Confidencialidade cliente-pentester.

---

### **15. Clean Machine**
```bash
# VM isolada para cada cliente
```

- [ ] VM dedicada por engagement
- [ ] Snapshot antes de começar
- [ ] Destruir VM após entrega

**Benefício:** Isolamento total entre clientes.

---

## 🚨 **SINAIS DE ALERTA** (Abortar operação se detectar)

| Sinal | Ação |
|-------|------|
| VPN desconecta | ❌ **PARAR IMEDIATAMENTE** - Kill switch |
| IP real exposto | ❌ **ABORTAR** - Trocar de IP/VPN |
| 429 (Too Many Requests) | ⏸️ **PAUSAR** - Aumentar delay |
| WAF detectado | ⚠️ **AJUSTAR** - Mudar técnica |
| Bloqueio de IP | ⚠️ **TROCAR** - Novo IP/Proxy |
| Contato do cliente | 📞 **COMUNICAR** - Reportar progresso |

---

## 📝 **Template de Checklist Diário**

```
Data: ___/___/____
Cliente: _________________
Escopo: _________________

PRÉ-OPERAÇÃO:
[ ] VPN ativa (IP: _____________)
[ ] DNS leak check OK
[ ] Autorização válida
[ ] Backup realizado
[ ] Recursos verificados

DURANTE:
[ ] Rate limiting ativo
[ ] User-Agent rotation
[ ] Logs habilitados
[ ] Screenshots de achados

PÓS-OPERAÇÃO:
[ ] Logs salvos
[ ] Evidências organizadas
[ ] Commits no Git
[ ] Relatório iniciado
```

---

## 🛠️ **Scripts Auxiliares**

```bash
# Checklist completo automatizado
source lib/opsec.sh
pre_engagement_check

# Verificar recursos
source lib/resource_check.sh
full_system_check

# Iniciar logging
script -a /var/log/pentest_$(date +%Y%m%d).log
```

---

## 📚 **Referências**

- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)
- [PTES - Penetration Testing Execution Standard](http://www.pentest-standard.org/)
- [Red Team Field Manual](https://www.amazon.com/Rtfm-Red-Team-Field-Manual/dp/1494295504)

---

**Última atualização:** 2025-11-28  
**Autor:** Samuel Ziger
