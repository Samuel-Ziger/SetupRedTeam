# 🤝 Guia de Contribuição

Obrigado por considerar contribuir para este repositório! Este documento fornece diretrizes para contribuições.

---

## 📋 Código de Conduta

Ao contribuir, você concorda em:

- Manter um ambiente respeitoso e profissional
- Respeitar diferentes pontos de vista e experiências
- Aceitar críticas construtivas com graça
- Focar no que é melhor para o projeto

---

## 🔀 Como Contribuir

### 1. Fork e Clone

```bash
# Fork o repositório no GitHub
# Clone seu fork
git clone https://github.com/SEU_USUARIO/SetupRedTeam.git
cd SetupRedTeam
```

### 2. Criar Branch

```bash
git checkout -b feature/nome-da-feature
# ou
git checkout -b fix/nome-do-fix
```

### 3. Fazer Mudanças

- Siga as convenções de código existentes
- Adicione comentários quando necessário
- Mantenha commits pequenos e focados
- Teste suas mudanças antes de commitar

### 4. Commit

```bash
git add .
git commit -m "Descrição clara e concisa da mudança"
```

**Formato de Commit:**
```
tipo: descrição curta

Descrição mais detalhada (se necessário)

- Item 1
- Item 2
```

**Tipos:**
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Mudanças na documentação
- `refactor`: Refatoração de código
- `test`: Adição de testes
- `chore`: Tarefas de manutenção

### 5. Push e Pull Request

```bash
git push origin feature/nome-da-feature
```

Depois, abra um Pull Request no GitHub.

---

## 📝 Diretrizes de Código

### Scripts Shell (Bash)

- Use `#!/bin/bash` no shebang
- Siga o estilo do código existente
- Adicione comentários para funções complexas
- Use variáveis para valores reutilizáveis
- Valide entradas do usuário

### Scripts PowerShell

- Use `#Requires -RunAsAdministrator` quando necessário
- Documente parâmetros
- Trate erros adequadamente
- Use Write-Host para output do usuário

### Scripts Python

- Siga PEP 8
- Use type hints quando possível
- Adicione docstrings
- Trate exceções apropriadamente

---

## 📚 Documentação

- Atualize a documentação quando necessário
- Use Markdown para documentos
- Mantenha exemplos atualizados
- Adicione comentários explicativos em código complexo

---

## 🧪 Testes

Antes de submeter:

1. Teste seus scripts em ambiente isolado
2. Verifique que não quebrou funcionalidades existentes
3. Teste em diferentes sistemas operacionais quando aplicável
4. Valide que a documentação está correta

---

## 🔍 Revisão de Código

Todas as contribuições passarão por revisão:

- Código será revisado quanto à qualidade e segurança
- Sugestões de melhoria podem ser feitas
- Mudanças podem ser solicitadas antes do merge

---

## 🐛 Reportando Bugs

Ao reportar bugs:

1. Verifique se o bug já não foi reportado
2. Use o template de issue fornecido
3. Forneça informações detalhadas:
   - Sistema operacional
   - Versão do script
   - Passos para reproduzir
   - Comportamento esperado vs. atual

---

## 💡 Sugerindo Funcionalidades

Ao sugerir funcionalidades:

1. Verifique se já não existe uma issue similar
2. Explique o problema que a funcionalidade resolveria
3. Descreva como a funcionalidade funcionaria
4. Considere casos de uso e alternativas

---

## 📄 Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a mesma licença do projeto.

---

## ❓ Perguntas?

Se tiver dúvidas, abra uma issue ou entre em contato com os mantenedores.

---

**Obrigado por contribuir! 🎉**
