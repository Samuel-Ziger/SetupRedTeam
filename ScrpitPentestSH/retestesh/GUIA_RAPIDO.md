# ⚡ Guia Rápido de Uso

## 🚀 Início Rápido

### 1. Executar TODOS os retestes:
```bash
cd retestesh
chmod +x executar_todos_retestes.sh
./executar_todos_retestes.sh
```

### 2. Executar reteste individual:
```bash
cd retestesh
chmod +x reteste_adivisao.sh
./reteste_adivisao.sh
```

---

## 📋 Scripts Disponíveis

| Script | Alvo | Tempo Estimado |
|--------|------|----------------|
| `reteste_adivisao.sh` | adivisao.com.br | ~2-3 min |
| `reteste_divisaodeelite.sh` | divisaodeelite.com.br | ~3-4 min |
| `reteste_acheumveterano.sh` | acheumveterano.com.br | ~2-3 min |
| `reteste_idivis.sh` | idivis.ao / 31.97.27.219 | ~3-4 min |
| `reteste_planodechamadas.sh` | planodechamadas.com.br | ~3-4 min |
| `reteste_ngrok.sh` | ngrok URL | ~1-2 min |
| `executar_todos_retestes.sh` | TODOS | ~15-20 min |

---

## 🎯 Por Onde Começar?

### Se você aplicou correções em um alvo específico:
```bash
./reteste_[alvo].sh
```

### Se quer verificar o status geral:
```bash
./executar_todos_retestes.sh
```

### Se quer ver as vulnerabilidades antes de testar:
```bash
cat INDICE_VULNERABILIDADES.md
```

---

## 📊 Interpretar Resultados

### Cores no Terminal:

- 🔴 **Vermelho**: Vulnerabilidade ainda presente (AÇÃO NECESSÁRIA)
- 🟡 **Amarelo**: Atenção necessária ou vulnerabilidade média
- 🟢 **Verde**: Proteção implementada (OK)

### Códigos HTTP Importantes:

- `200`: Recurso acessível (⚠️ pode ser ruim para arquivos sensíveis)
- `404/403`: Recurso bloqueado (✅ bom para proteção)
- `429`: Rate limiting ativo (✅ bom)

---

## 📁 Onde Estão os Relatórios?

Cada execução cria uma pasta com timestamp:
```
reteste_[alvo]_YYYYMMDD_HHMMSS/
```

Exemplo:
```
reteste_adivisao_20251128_143052/
├── 01_tokens_expostos.txt
├── 02_elasticsearch_enum.txt
├── 03_cors_test.txt
└── ...
```

---

## ⚠️ Problemas Comuns

### "Permission denied"
```bash
chmod +x *.sh
```

### "Command not found: curl"
```bash
# Linux
sudo apt install curl

# Windows (usar Git Bash ou WSL)
```

### "Connection timeout"
- Verificar se alvo está acessível
- Verificar firewall/VPN
- Verificar se ngrok URL não expirou

---

## 🔄 Fluxo de Trabalho

```
1. Ler vulnerabilidades → INDICE_VULNERABILIDADES.md
2. Aplicar correções    → Nos servidores/aplicações
3. Executar reteste     → ./reteste_[alvo].sh
4. Analisar relatório   → Verificar pasta criada
5. Documentar correção  → Marcar como resolvido
6. Repetir para próximo → Até todos corrigidos
```

---

## 📞 Checklist Rápido

Antes de executar os scripts:

- [ ] Tenho autorização para testar?
- [ ] Scripts têm permissão de execução? (`chmod +x`)
- [ ] Estou no diretório correto? (`cd retestesh`)
- [ ] Ferramentas instaladas? (`curl`, `nc`, `openssl`)

---

## 🎯 Prioridades

### Execute PRIMEIRO (Crítico):
1. `reteste_idivis.sh` - Porta 3000 + arquivos sensíveis
2. `reteste_divisaodeelite.sh` - Plugin malicioso
3. `reteste_acheumveterano.sh` - SSH vulnerável

### Execute DEPOIS (Importante):
4. `reteste_adivisao.sh` - Tokens + Elasticsearch
5. `reteste_planodechamadas.sh` - Headers + Next.js

### Execute POR ÚLTIMO (Informativo):
6. `reteste_ngrok.sh` - URL temporária

---

## 💡 Dicas

- ✅ Execute retestes **após cada correção**
- ✅ Salve os relatórios para comparação
- ✅ Documente o que foi corrigido
- ✅ Re-teste periodicamente (mensal)
- ❌ Não execute em produção sem autorização
- ❌ Não compartilhe relatórios publicamente

---

## 📖 Documentação Completa

- `README.md` - Documentação detalhada
- `INDICE_VULNERABILIDADES.md` - Lista de vulnerabilidades
- Este arquivo - Guia rápido

---

## 🆘 Ajuda

**Erros nos scripts?**
1. Verificar permissões (`ls -la`)
2. Verificar ferramentas (`which curl nc openssl`)
3. Verificar conectividade (`ping [alvo]`)

**Dúvidas sobre vulnerabilidades?**
- Consultar `INDICE_VULNERABILIDADES.md`
- Revisar relatórios originais nas pastas dos alvos

**Precisa de mais informações?**
- Ler `README.md` completo
- Analisar o código dos scripts

---

**Criado**: 28/11/2025  
**Versão**: 1.0  
**Autor**: Samuel Ziger
