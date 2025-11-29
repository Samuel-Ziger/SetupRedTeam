# Guia de Uso — SQL Injection Automation Script (Versão Profissional)

## Visão Geral

Este script automatiza testes de SQL Injection em múltiplos alvos, com auditoria, OPSEC, logs corporativos, detecção de WAF, integração Metasploit e suporte a escopos profissionais. Ideal para times de Red Team, consultorias e auditorias formais.

---

## Pré-requisitos
- Kali Linux ou similar
- Permissão root
- Ferramentas: `sqlmap`, `jq`, `curl`, `proxychains`, `tor`, `docker` (opcional para injector)
- Arquivo digital de autorização (PDF/JPG/PNG)
- (Opcional) Arquivo de escopo com múltiplas URLs

---

## Estrutura de Pastas
- `result/` — Resultados gerais
- `result/logs/` — Logs detalhados (JSONL, CSV, .log)
- `result/relatorio/` — Relatórios finais
- `result/dumps/` — Dumps de bancos de dados
- `lib/` — Funções auxiliares (log, opsec, sqlmap)
- `modules/` — Módulos extras (dump, etc)

---

## Execução Básica

1. **Dê permissão de execução:**
   ```bash
   chmod +x sql_injection_automatizado.sh
   ```

2. **Execute como root:**
   ```bash
   sudo ./sql_injection_automatizado.sh
   ```

3. **Siga o fluxo interativo:**
   - Anexe o arquivo digital de autorização
   - Informe número do processo, responsável e tempo de retenção
   - Escolha se deseja instalar/verificar ferramentas
   - Informe a(s) URL(s) alvo(s) ou arquivo de escopo
   - Informe dados POST se necessário
   - Escolha ativar detecção/bypass de WAF
   - Escolha rodar Metasploit após SQLi (opcional)

---

## Suporte a Múltiplos Alvos
- Para testar vários alvos, crie um arquivo de texto (um por linha):
  ```
  https://site1.com/vuln.php?id=1
  https://site2.com/search.php?q=abc
  ...
  ```
- O script processa cada alvo em fila controlada (máx 2 em paralelo).

---

## Auditoria e Compliance
- Exige arquivo digital de autorização e registra metadados (número, responsável, retenção, IP, hash da máquina).
- Gera logs imutáveis em JSONL e CSV corporativo.
- Gera hash SHA256 dos relatórios e arquivos críticos.

---

## Logs e Relatórios
- `logs/main.log` — Log geral
- `logs/auditoria.jsonl` — Auditoria e compliance
- `logs/sqlmap_results.jsonl` — Resultados parseados do SQLMap
- `logs/sqlmap_results.csv` — Resultados em CSV
- `relatorio/relatorio_*.txt` — Relatório final detalhado

---

## Dicas Profissionais
- Use sempre escopo autorizado e documente tudo.
- Ative detecção de WAF para ambientes corporativos.
- Exporte dumps/credenciais apenas se autorizado.
- Integre com Metasploit para pós-exploração.
- Todos os comandos e resultados são auditáveis.

---

## Integração Metasploit
- O script pode rodar módulos do Metasploit após SQLi.
- Informe o módulo e o alvo quando solicitado.

---

## Exportação de Dados
- Dumps de bancos e credenciais são salvos em `result/dumps/`.
- Logs parseados em JSONL e CSV para integração com SIEMs.

---

## Segurança e Limites
- Nunca execute sem autorização formal.
- O script não substitui análise manual — use como apoio.
- Não rode em produção sem consentimento explícito.

---

## Suporte e Customização
- Modularize funções em `lib/` e `modules/` conforme sua política.
- Adapte técnicas, delays e paralelismo conforme o ambiente.

---

## Exemplo de Execução
```bash
sudo ./sql_injection_automatizado.sh
# Siga as instruções na tela
```

---

## Dúvidas?
Consulte o código-fonte, leia os logs e adapte para seu workflow corporativo.

---

**Desenvolvido para uso profissional, auditoria e Red Team.**
