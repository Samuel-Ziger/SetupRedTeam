# 📁 Output Padronizado

Esta pasta contém todos os resultados dos testes de penetração organizados de forma padronizada.

## ⚠️ Importante

Esta pasta está no `.gitignore` para evitar commit acidental de informações sensíveis.

**NUNCA faça commit de arquivos desta pasta!**

## 📁 Estrutura

```
output/
├── recon/          # Resultados de reconhecimento
├── exploits/       # Resultados de exploração
├── creds/          # Credenciais encontradas (⚠️ SENSÍVEL)
├── screenshots/    # Screenshots/evidências
└── reports/        # Relatórios finais
```

## 🔒 Segurança

- ⚠️ **NÃO commitar:** Esta pasta contém informações sensíveis
- ⚠️ **Criptografar:** Credenciais encontradas devem ser criptografadas
- ⚠️ **Validar permissões:** Garantir que arquivos sensíveis tenham permissões adequadas (chmod 600)

## 📝 Uso

Os scripts de pentest automaticamente salvam resultados aqui seguindo o padrão:

- `recon/` - Resultados de ferramentas de reconhecimento (subfinder, nmap, etc.)
- `exploits/` - Resultados de exploração e exploits
- `creds/` - Credenciais, hashes, tokens encontrados
- `screenshots/` - Screenshots de websites, aplicações, etc.
- `reports/` - Relatórios finais em Markdown, PDF, HTML

## 🧹 Limpeza

Para limpar resultados antigos:

```bash
# Limpar todos os resultados (cuidado!)
rm -rf output/*

# Ou limpar categoria específica
rm -rf output/recon/*
```

---

**Nota:** Esta estrutura está padronizada conforme documentado em `ESTRUTURA_FINAL.md`
