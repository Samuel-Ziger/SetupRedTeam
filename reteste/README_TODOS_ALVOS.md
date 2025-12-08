# Script de Pentest em Todos os Alvos

Este script executa o pentest automatizado em **todos os alvos** identificados nos relatórios anteriores.

## 📋 Alvos Incluídos

### Domínios Principais
1. **planodechamadas.com.br** (IP: 31.97.27.219)
2. **adivisao.com.br**
3. **acheumveterano.com.br** (IP: 72.60.255.201)
4. **divisaodeelite.com.br**
5. **idivis.ao** (IP: 31.97.27.219)

### Subdomínios
6. **lp.planodechamadas.com.br** (IP: 31.97.168.34)
7. **app.acheumveterano.com.br**

### IPs Diretos
8. **31.97.27.219**
9. **31.97.168.34**
10. **72.60.255.201**

**Total: 10 alvos**

## 🚀 Como Usar

### Opção 1: Script Python

```bash
python3 pentest_all_targets.py
```

O script irá:
1. Listar todos os alvos
2. Perguntar se deseja pular a fase de exploração
3. Executar o pentest em cada alvo sequencialmente
4. Gerar um resumo final

### Opção 2: Script Shell

```bash
chmod +x pentest_all_targets.sh
./pentest_all_targets.sh
```

## ⚙️ Opções

### Pular Fase de Exploração (Recomendado)

Por padrão, o script pergunta se deseja pular a fase de exploração. Isso é recomendado porque:
- Executa mais rápido
- Menos invasivo
- Ainda gera relatórios completos de OSINT e infraestrutura

### Executar com Exploração

Se você responder "n" quando perguntado, o script executará a fase de exploração em cada alvo (requer autorização para cada um).

## 📁 Estrutura de Saída

Todos os resultados serão salvos em:

```
pentest_results_all/
├── planodechamadas_com_br/
│   ├── Relatorio_Fase1_*.md
│   └── ...
├── adivisao_com_br/
│   ├── Relatorio_Fase1_*.md
│   └── ...
├── acheumveterano_com_br/
│   └── ...
└── ...
```

## ⏱️ Tempo Estimado

- **Por alvo (sem exploração)**: 30-60 minutos
- **Por alvo (com exploração)**: 60-120 minutos
- **Total (10 alvos, sem exploração)**: 5-10 horas
- **Total (10 alvos, com exploração)**: 10-20 horas

## 📊 Resumo Final

Ao final da execução, o script exibe:
- Número de alvos testados com sucesso
- Número de falhas
- Tempo total de execução
- Localização dos resultados

## ⚠️ Avisos Importantes

1. **Autorização**: Certifique-se de ter autorização para testar **TODOS** os alvos
2. **Tempo**: A execução completa pode levar várias horas
3. **Recursos**: O script usa recursos de rede e CPU intensivamente
4. **Interrupção**: Você pode interromper a qualquer momento com Ctrl+C
5. **Pausa**: O script faz uma pausa de 5 segundos entre cada alvo

## 🔧 Personalização

### Editar Lista de Alvos

Edite o arquivo `pentest_all_targets.py` e modifique a lista `TARGETS`:

```python
TARGETS = [
    "seu-alvo.com.br",
    "outro-alvo.com.br",
    # ...
]
```

### Remover Alvos Específicos

Comente ou remova alvos da lista que você não deseja testar:

```python
TARGETS = [
    "planodechamadas.com.br",
    # "adivisao.com.br",  # Comentado - não será testado
    "acheumveterano.com.br",
    # ...
]
```

### Alterar Pausa Entre Alvos

No arquivo `pentest_all_targets.py`, modifique:

```python
time.sleep(5)  # Altere o valor (em segundos)
```

## 📝 Exemplo de Execução

```
============================================================
  SCRIPT DE PENTEST EM TODOS OS ALVOS
============================================================

Alvos identificados nos relatórios:
  1. planodechamadas.com.br
  2. adivisao.com.br
  3. acheumveterano.com.br
  ...

Total de alvos: 10
AVISO: Certifique-se de ter autorização para testar todos os alvos!

Deseja pular a fase de exploração em todos os alvos? (S/n): s
[INFO] Fase de exploração será pulada em todos os alvos

Pronto para iniciar?
Pressione Enter para continuar ou Ctrl+C para cancelar...

============================================================
Alvo 1/10: planodechamadas.com.br
============================================================

[INFO] Iniciando pentest em: planodechamadas.com.br
...
[SUCCESS] Pentest concluído com sucesso: planodechamadas.com.br

============================================================
  RESUMO FINAL
============================================================

Alvos testados com sucesso: 10/10
Tempo total: 8 horas e 32 minutos

Resultados salvos em: pentest_results_all/
```

## 🐛 Troubleshooting

### Erro: "pentest_automation.py não encontrado"
Certifique-se de que o arquivo `pentest_automation.py` está no mesmo diretório.

### Interrupção Durante Execução
Se você interromper a execução (Ctrl+C), os resultados dos alvos já testados serão mantidos. Você pode executar novamente e o script testará apenas os alvos restantes (ou todos, dependendo da configuração).

### Falha em um Alvo Específico
O script continua mesmo se um alvo falhar. Verifique os logs para identificar o problema.

## 📚 Relacionado

- `pentest_automation.py`: Script principal de pentest
- `README_PENTEST.md`: Documentação completa do script principal
- `EXEMPLO_USO.md`: Exemplos de uso do script principal

---

**Lembre-se: Sempre obtenha autorização antes de executar testes de penetração!**

