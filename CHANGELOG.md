# 📝 Changelog - Scripts-Bat

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

---

## [1.0.0] - 2025-11-28

### 📚 Documentação

#### Adicionado
- ✅ **INDEX.md** - Índice completo de navegação do repositório
- ✅ **ScrpitPentestSH/README.md** - Overview dos scripts de pentest
- ✅ **CHANGELOG.md** - Este arquivo

#### Atualizado
- ✅ **README.md** - Seção completa sobre scripts de pentest
- ✅ **README.md** - Estatísticas precisas (54 vulnerabilidades rastreadas)
- ✅ **README.md** - Seção de recursos externos úteis
- ✅ **README.md** - Estrutura de diretórios completa
- ✅ **Windows/README.md** - Contagem correta de 18 scripts
- ✅ **Windows/README.md** - Seção sobre scripts de bloqueio
- ✅ **ScrpitPentestSH/retestesh/README.md** - Seção sobre script mestre e versões legacy

### 🆕 Novos Scripts

#### Windows
- ✅ `atack2.0-optimized.bat` - Setup otimizado para Notebook 2 (AD/Lateral Movement)
- ✅ `rollback.bat` - Reverter todas as configurações do setup
- ✅ `NOTEBOOK2-GUIDE.md` - Guia especializado de 400+ linhas

#### Pentest
- ✅ `retestesh/executar_todos_retestes.sh` - Script mestre que executa todos os retestes
- ✅ `retestesh/GUIA_RAPIDO.md` - Guia de início rápido
- ✅ `retestesh/INDICE_VULNERABILIDADES.md` - Índice de 54 vulnerabilidades
- ✅ Scripts organizados em `retestesh/` (7 scripts)

### 🔧 Melhorias

#### Scripts Windows
- ✅ Verificação de arquivos existentes antes de baixar
- ✅ Mensagens informativas em português
- ✅ Melhor tratamento de erros
- ✅ Não clona/baixa ferramentas já existentes

#### Scripts de Reteste
- ✅ Relatórios com timestamp automático
- ✅ Códigos de cores (🔴 Crítico, 🟡 Médio, 🟢 OK)
- ✅ Verificação completa de headers de segurança
- ✅ Testes de portas e serviços
- ✅ Validação TLS/SSL
- ✅ Script consolidado para executar todos os retestes

### 📊 Estatísticas

- **Total de READMEs:** 8 arquivos
- **Scripts Windows:** 18 (4 principais + 10 auxiliares + 2 descontinuados + 2 docs)
- **Scripts Pentest:** 13 (7 retestesh + 5 legacy + 1 DDoS)
- **Ferramentas Kali:** 29 toolkits
- **Vulnerabilidades rastreadas:** 54 em 6 alvos
- **Documentação total:** ~3,500 linhas

---

## [0.9.0] - 2025-11 (Anterior)

### Inicial
- ✅ Setup básico Kali Linux (`setup-kali.sh`)
- ✅ Setup básico Windows (`atack2.0.bat`, `setup-attackbox.ps1`)
- ✅ 29 ferramentas Kali organizadas
- ✅ Scripts de reteste individuais (versão legacy)
- ✅ READMEs básicos

---

## 🎯 Próximas Versões (Roadmap)

### [1.1.0] - Planejado

#### Melhorias de Scripts
- [ ] Adicionar logging detalhado em todos os scripts
- [ ] Criar modo silencioso para setup automatizado
- [ ] Adicionar checksum verification para downloads
- [ ] Implementar retry logic em downloads que falharem

#### Documentação
- [ ] Vídeos tutoriais de setup
- [ ] Screenshots das ferramentas principais
- [ ] Guia de troubleshooting expandido
- [ ] Tradução para inglês

#### Novos Recursos
- [ ] Script de backup/restore completo
- [ ] Dashboard web para visualização de retestes
- [ ] Integração com CI/CD para retestes automáticos
- [ ] Notificações via webhook (Discord/Slack)

#### Ferramentas
- [ ] Adicionar mais ferramentas de OSINT
- [ ] Integrar ferramentas de cloud security
- [ ] Adicionar scanners de container security

---

## 📋 Convenções de Versionamento

Este projeto segue [Semantic Versioning](https://semver.org/):
- **MAJOR** (1.x.x) - Mudanças incompatíveis
- **MINOR** (x.1.x) - Novas funcionalidades compatíveis
- **PATCH** (x.x.1) - Correções de bugs

### Categorias de Mudanças
- **Adicionado** - Novas funcionalidades
- **Modificado** - Mudanças em funcionalidades existentes
- **Descontinuado** - Funcionalidades que serão removidas
- **Removido** - Funcionalidades removidas
- **Corrigido** - Correções de bugs
- **Segurança** - Correções de vulnerabilidades

---

## 🔗 Links Úteis

- [README Principal](./README.md)
- [Índice Completo](./INDEX.md)
- [Repositório GitHub](https://github.com/Samuel-Ziger/Scripts-Bat)

---

**Formato baseado em:** [Keep a Changelog](https://keepachangelog.com/)  
**Versionamento:** [Semantic Versioning](https://semver.org/)  
**Última atualização:** 28/11/2025
