# Exemplos de Uso do Script de Pentest

## Exemplos Práticos

### 1. Teste Básico em Domínio

```bash
python3 pentest_automation.py planodechamadas.com.br
```

Este comando executará:
- OSINT completo
- Reconhecimento de infraestrutura
- Detecção de vulnerabilidades
- Solicitará autorização para fase de exploração

### 2. Teste Apenas de Reconhecimento (Sem Exploração)

```bash
python3 pentest_automation.py adivisao.com.br --skip-exploitation
```

Útil quando você quer apenas coletar informações sem realizar testes invasivos.

### 3. Teste em IP Direto

```bash
python3 pentest_automation.py 31.97.27.219
```

O script detecta automaticamente se é um IP ou domínio.

### 4. Especificar Diretório de Saída Personalizado

```bash
python3 pentest_automation.py exemplo.com.br -o resultados_pentest_2025
```

### 5. Usando o Script Shell Auxiliar

```bash
./run_pentest.sh acheumveterano.com.br
```

Ou com opções:

```bash
./run_pentest.sh divisaodeelite.com.br --skip-exploitation
```

## Fluxo de Execução

### Fase 1: OSINT (15-30 minutos)
```
[INFO] Iniciando coleta WHOIS...
[SUCCESS] WHOIS concluído
[INFO] Iniciando enumeração DNS...
[SUCCESS] IP principal identificado: 31.97.27.219
[INFO] Iniciando enumeração de subdomínios (Sublist3r)...
[SUCCESS] Encontrados 3 subdomínios
...
```

### Fase 2: Infraestrutura (30-60 minutos)
```
[INFO] Iniciando scan de portas (Nmap)...
[SUCCESS] Portas abertas encontradas: 22, 80, 443, 3000
[INFO] Iniciando scan web (Nikto)...
[SUCCESS] Nikto concluído
...
```

### Fase 3: Detecção de Vulnerabilidades (instantâneo)
```
[WARNING] Vulnerabilidade detectada: Ausência de CSP (Alta)
[WARNING] Vulnerabilidade detectada: Porta 22 (SSH) exposta (Alta)
[SUCCESS] Total de vulnerabilidades detectadas: 5
```

### Fase 4: Exploração (com autorização)
```
============================================================
ATENÇÃO: FASE DE EXPLORAÇÃO
============================================================
A próxima fase realizará testes de exploração que podem ser invasivos.
Deseja continuar com a fase de exploração? (s/N): s

[WARNING] Testando brute force SSH...
[INFO] Testando usuário: root (limitado a 10 tentativas)
...
```

## Estrutura de Resultados

Após a execução, você terá:

```
pentest_results/
└── planodechamadas_com_br/
    ├── osint_data_20250102_143022.json
    ├── infra_data_20250102_143022.json
    ├── exploitation_data_20250102_143022.json
    ├── Relatorio_Fase1_20250102_143022.md
    ├── Relatorio_Fase2_20250102_143022.md
    ├── whois_20250102_143022.txt
    ├── dig_20250102_143022.txt
    ├── nmap_quick_20250102_143022.nmap
    ├── nikto_20250102_143022.txt
    └── ...
```

## Interpretando os Relatórios

### Relatório Fase 1

O relatório da Fase 1 contém:
1. **Resumo Executivo**: Visão geral do teste
2. **Informações OSINT**: Todos os dados públicos coletados
3. **Reconhecimento de Infraestrutura**: Portas, serviços, diretórios
4. **Vulnerabilidades Identificadas**: Lista priorizada por severidade

### Relatório Fase 2

O relatório da Fase 2 contém:
1. **Testes de Exploração**: Resultados dos testes invasivos
2. **Vulnerabilidades Exploradas**: Evidências de exploração bem-sucedida
3. **Recomendações Finais**: Correções prioritárias

## Dicas de Uso

### 1. Primeira Execução
Execute primeiro apenas com `--skip-exploitation` para entender o escopo:

```bash
python3 pentest_automation.py alvo.com.br --skip-exploitation
```

### 2. Análise dos Resultados
Revise os arquivos JSON para dados estruturados:
- `osint_data_*.json`: Dados OSINT em formato JSON
- `infra_data_*.json`: Dados de infraestrutura
- `exploitation_data_*.json`: Dados de exploração

### 3. Relatórios para Cliente
Use os arquivos `.md` (Markdown) que podem ser convertidos para PDF:
- `Relatorio_Fase1_*.md`
- `Relatorio_Fase2_*.md`

### 4. Múltiplos Alvos
Para testar múltiplos alvos, crie um script:

```bash
#!/bin/bash
for target in alvo1.com.br alvo2.com.br alvo3.com.br; do
    python3 pentest_automation.py "$target" --skip-exploitation
done
```

## Troubleshooting

### Erro: "Ferramenta não encontrada"
Instale a ferramenta faltante:
```bash
sudo apt install <nome_da_ferramenta>
```

### Timeout em comandos
Alguns comandos podem demorar. O script continua mesmo se uma ferramenta falhar.

### Permissões
Algumas ferramentas precisam de sudo:
```bash
sudo python3 pentest_automation.py alvo.com.br
```

## Integração com Outras Ferramentas

### Burp Suite
Use os resultados do Gobuster/FFuF para importar no Burp Suite:
1. Exporte os endpoints encontrados
2. Importe no Burp Suite como sitemap

### Metasploit
Use as vulnerabilidades identificadas para buscar exploits:
```bash
msfconsole
search <vulnerabilidade>
```

### Relatórios Profissionais
Combine os relatórios Markdown com ferramentas como:
- Pandoc (conversão para PDF)
- Dillinger (editor Markdown online)
- GitBook (documentação profissional)

## Boas Práticas

1. **Sempre obtenha autorização** antes de executar
2. **Documente a autorização** (email, contrato, etc.)
3. **Execute em horários apropriados** (evite horários de pico)
4. **Monitore o impacto** durante os testes
5. **Comunique problemas** imediatamente se algo der errado
6. **Mantenha logs** de todas as execuções
7. **Revise os relatórios** antes de entregar ao cliente

## Próximos Passos

Após executar o pentest:

1. **Analise os relatórios** gerados
2. **Priorize as vulnerabilidades** por severidade
3. **Documente evidências** adicionais se necessário
4. **Prepare recomendações** de correção
5. **Agende re-teste** após correções
6. **Valide as correções** aplicadas

---

**Lembre-se: Pentest é uma ferramenta de segurança, não de ataque. Use com responsabilidade!**

