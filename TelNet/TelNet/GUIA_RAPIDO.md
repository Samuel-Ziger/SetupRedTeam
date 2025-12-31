# Guia Rápido de Uso

## 🚀 Início Rápido

### 1. Teste Rápido - Senhas Padrão (Recomendado Primeiro)

```bash
python telnet_main.py --defaults 192.168.1.1
```

Este comando testa senhas padrão comuns de roteadores ZTE. É muito mais rápido que o bruteforce completo e muitas vezes funciona!

### 2. Coletar Informações do Serviço

```bash
python telnet_main.py --info 192.168.1.1
```

Coleta banner, versão e características do serviço Telnet.

### 3. Bruteforce Completo

Se as senhas padrão não funcionarem:

```bash
python telnet_main.py --bruteforce 192.168.1.1 xato_net_passwords.txt
# Uso básico (usa root/public automaticamente)
python telnet_enable_bruteforce.py 192.168.1.1 xato_net_passwords.txt   
```

### 4. Análise Completa (Tudo Junto)

```bash
python telnet_main.py --all 192.168.1.1 xato_net_passwords.txt
```

## 📋 Fluxo Recomendado

1. **Primeiro**: Teste senhas padrão (`--defaults`)
2. **Se não funcionar**: Colete informações (`--info`)
3. **Depois**: Faça bruteforce completo (`--bruteforce`)

## ⚡ Otimizações

### Para Bruteforce Mais Rápido

```bash
python telnet_main.py --bruteforce 192.168.1.1 xato_net_passwords.txt \
    --threads 10 \
    --delay 0.2
```

**Atenção**: Muitas threads e delay baixo podem causar bloqueios ou timeouts.

### Para Bruteforce Mais Seguro (Evitar Bloqueios)

```bash
python telnet_main.py --bruteforce 192.168.1.1 xato_net_passwords.txt \
    --threads 3 \
    --delay 1.0
```

## 🔍 Exemplos Práticos

### Exemplo 1: Teste Rápido
```bash
# Testa senhas padrão (leva alguns segundos)
python telnet_main.py --defaults 192.168.1.1
```

### Exemplo 2: Análise Completa
```bash
# Coleta info + testa padrões + bruteforce
python telnet_main.py --all 192.168.1.1 xato_net_passwords.txt --threads 5
```

### Exemplo 3: Apenas Informações
```bash
# Apenas coleta informações sem tentar login
python telnet_main.py --info 192.168.1.1
```

## ⚠️ Dicas Importantes

1. **Sempre comece com `--defaults`**: É muito mais rápido e muitas vezes funciona
2. **Use delay adequado**: Delay muito baixo pode causar bloqueios
3. **Monitore o progresso**: O script mostra progresso a cada 100 tentativas
4. **Interrompa com Ctrl+C**: Pode interromper a qualquer momento com segurança

## 🐛 Solução de Problemas

### Erro de Conexão
- Verifique se o IP está correto
- Verifique se a porta 23 está aberta
- Verifique se há firewall bloqueando

### Timeout
- Aumente o `--timeout` (padrão: 10 segundos)
- Aumente o `--delay` entre tentativas

### Falsos Positivos
- O script já detecta falsos positivos automaticamente
- Se ainda houver problemas, verifique manualmente as credenciais encontradas

## 📊 Estatísticas

O script mostra:
- Total de tentativas realizadas
- Taxa de sucesso
- Senha encontrada (se houver)
- Tempo decorrido

