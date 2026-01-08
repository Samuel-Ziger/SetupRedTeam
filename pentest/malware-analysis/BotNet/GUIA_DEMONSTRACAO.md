# 🎓 Guia Rápido de Demonstração para Palestra

## ⚡ Início Rápido (5 minutos)

### 1. Preparação (Antes da Palestra)
```bash
# Certifique-se de que está na pasta do projeto
cd botnet

# Teste se o Python está funcionando
python --version  # Deve ser 3.6+
```

### 2. Durante a Palestra - Passo a Passo

#### Terminal 1: Servidor Alvo
```bash
python target_server.py
```
**O que mostrar**: "Este é o servidor que será atacado. Veja que ele está funcionando normalmente."

#### Terminal 2: Servidor C&C
```bash
python cc_server.py
```
**O que mostrar**: "Este é o servidor de comando e controle. Ele aguarda bots se conectarem."

#### Terminal 3, 4, 5...: Bots
```bash
python bot.py Bot1
python bot.py Bot2
python bot.py Bot3
```
**O que mostrar**: "Agora temos 3 bots conectados ao C&C. Veja como eles aparecem no servidor."

#### No Terminal do C&C: Iniciar Ataque
```
CC> status
CC> attack 127.0.0.1 8080 30
```
**O que mostrar**: 
- "Agora vou ordenar que todos os bots ataquem simultaneamente"
- "Observe o servidor alvo - veja o aumento de requisições"
- "Isso demonstra como um DDoS funciona na prática"

---

## 📊 Pontos para Enfatizar

### 1. Arquitetura Botnet
- **Bots**: Dispositivos comprometidos
- **C&C**: Servidor central de controle
- **Alvo**: Sistema que será atacado

### 2. Escalabilidade
- "Com 3 bots, vemos X requisições/segundo"
- "Imagine com milhares de bots..."
- "Isso é o que acontece em ataques reais"

### 3. Coordenação
- "Veja como o C&C coordena todos os bots"
- "Um único comando afeta todos simultaneamente"
- "Isso mostra o poder de uma botnet"

### 4. Impacto
- "Observe como as requisições aumentam"
- "O servidor começa a ficar sobrecarregado"
- "Em um ataque real, isso derrubaria o serviço"

---

## 🎯 Roteiro Sugerido (15 minutos)

### Parte 1: Introdução (2 min)
- "Vou demonstrar como funciona uma botnet e um ataque DDoS"
- "Tudo está rodando localmente, apenas para demonstração"
- "Em um ataque real, isso seria ilegal e causaria danos"

### Parte 2: Setup (3 min)
- Iniciar servidor alvo
- Iniciar servidor C&C
- Conectar 3-5 bots
- Mostrar status: "Temos X bots conectados"

### Parte 3: Ataque (5 min)
- Explicar o que vai acontecer
- Executar comando de ataque
- Mostrar impacto no servidor alvo
- Explicar estatísticas (RPS, requisições totais)

### Parte 4: Análise (3 min)
- "Como isso funciona na prática?"
- "Como detectar uma botnet?"
- "Como se proteger?"

### Parte 5: Encerramento (2 min)
- Parar o ataque
- Encerrar componentes
- Reforçar aspectos legais e éticos

---

## 💡 Dicas para a Apresentação

### Visual
- Use múltiplos monitores se possível
- Terminal 1: Servidor alvo (mostra impacto)
- Terminal 2: C&C (mostra controle)
- Terminal 3+: Bots (mostra escala)

### Timing
- Não deixe o ataque rodar muito tempo
- 30 segundos é suficiente para demonstração
- Pare antes que a audiência perca interesse

### Linguagem
- Use termos técnicos, mas explique
- "C&C" = "Command and Control"
- "DDoS" = "Distributed Denial of Service"
- "RPS" = "Requisições por Segundo"

### Interatividade
- Pergunte: "Quantos bots vocês acham que são necessários?"
- "O que aconteceria com 1000 bots?"
- "Como vocês protegeriam um servidor?"

---

## ⚠️ Pontos Legais a Enfatizar

1. **"Isso é apenas uma simulação"**
   - Funciona apenas localmente
   - Não representa uma ameaça real
   - Apenas para educação

2. **"Em um ataque real..."**
   - Seria ilegal
   - Causaria danos reais
   - Resultaria em consequências legais

3. **"O objetivo é..."**
   - Entender como funciona
   - Aprender a detectar
   - Desenvolver defesas

---

## 🔧 Troubleshooting

### Problema: "Address already in use"
**Solução**: Alguém já está usando a porta. Feche outros processos ou mude a porta no código.

### Problema: Bots não conectam
**Solução**: Verifique se o C&C está rodando e se a porta está correta (9999).

### Problema: Ataque não funciona
**Solução**: Verifique se há bots conectados (`status` no C&C) e se o servidor alvo está rodando.

### Problema: Muitas requisições travam o sistema
**Solução**: Reduza o número de bots ou aumente o delay no código do bot.

---

## 📝 Checklist Pré-Palestra

- [ ] Python 3.6+ instalado
- [ ] Todos os arquivos no mesmo diretório
- [ ] Testar execução de cada componente
- [ ] Preparar terminais/monitores
- [ ] Revisar roteiro
- [ ] Preparar slides de apoio
- [ ] Reforçar avisos legais

---

## 🎬 Script de Demonstração Completo

```bash
# Terminal 1
python target_server.py

# Terminal 2 (aguardar 2 segundos)
python cc_server.py

# Terminal 3, 4, 5 (um após o outro)
python bot.py Bot1
python bot.py Bot2
python bot.py Bot3

# No Terminal 2 (C&C), após bots conectarem:
CC> status
CC> attack 127.0.0.1 8080 30

# Aguardar 30 segundos, mostrar resultados
# Parar ataque:
CC> stop
```

---

**Boa apresentação! 🎓**

