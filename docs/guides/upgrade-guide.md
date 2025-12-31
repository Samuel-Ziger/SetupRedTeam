# 🔧 Guia de Upgrade de Hardware - Red Team Arsenal

## 📊 **Situação Atual (Análise)**

### **PC1 - i5-12400F / 32GB RAM**
**Função:** Proxmox + VMs (infraestrutura estável)

| Componente | Status | Nota |
|------------|--------|------|
| CPU | ✅ **EXCELENTE** | 6 cores modernos |
| RAM | ✅ **ÓTIMO** | 32GB suficiente para 5-6 VMs |
| Storage | ⚠️ **LIMITADO** | NVMe 256GB + 2x SATA 256GB |
| GPU | ✅ **OK** | RX 580 (não crítico para servidor) |

**Prioridade de upgrade:** 🟡 **MÉDIA** (funcional, mas pode melhorar)

---

### **PC2 - i5-3330 / 8GB RAM**
**Função:** Kali pesado (scans, exploits, fuzzing)

| Componente | Status | Nota |
|------------|--------|------|
| CPU | ⚠️ **LIMITADO** | i5 3ª geração (2012) - 4 cores |
| RAM | 🔴 **CRÍTICO** | 8GB insuficiente para operações pesadas |
| Storage | ✅ **OK** | SSD SATA 256GB |
| GPU | ✅ **OK** | Integrada (não crítico) |

**Prioridade de upgrade:** 🔴 **ALTA** (bottleneck em RAM)

---

### **Notebook 1 - Celeron N4020 / 4GB RAM**
**Função:** Stealth box (pivot, phishing, persistência)

| Componente | Status | Nota |
|------------|--------|------|
| CPU | ✅ **ADEQUADO** | Celeron suficiente para uso stealth |
| RAM | ✅ **ADEQUADO** | 4GB OK para função |
| Storage | ✅ **OK** | NVMe 128GB |

**Prioridade de upgrade:** 🟢 **BAIXA** (função não exige poder)

---

### **Notebook 2 - i5-3210M / 12GB RAM**
**Função:** Windows Attack Box (AD, Bloodhound, lateral movement)

| Componente | Status | Nota |
|------------|--------|------|
| CPU | ⚠️ **LIMITADO** | i5 2ª geração (2012) - 2 cores |
| RAM | ✅ **BOM** | 12GB suficiente |
| Storage | ✅ **OK** | SATA 256GB |

**Prioridade de upgrade:** 🟡 **MÉDIA** (RAM salva, mas CPU antiga)

---

## 🎯 **Plano de Upgrade Prioritário**

### **🔴 PRIORIDADE 1 - PC2: +8GB RAM** 
**Custo:** R$ 100-150  
**Impacto:** ⭐⭐⭐⭐⭐ (ENORME)  
**Tempo de instalação:** 5 minutos

**Por quê:**
- ✅ PC2 faz scans pesados (Masscan, Nmap, Hydra)
- ✅ 8GB **trava** com Metasploit + Burp + proxies
- ✅ 16GB total = confortável para multitasking

**Como fazer:**
```bash
# Verificar tipo de RAM atual
sudo dmidecode --type memory | grep -E "Type:|Speed:|Size:"

# Comprar:
# - DDR3 1600MHz ou 1333MHz
# - 8GB (1x8GB ou 2x4GB)
# - Mesma frequência da RAM atual
```

**Onde comprar:**
- Mercado Livre: R$ 80-120 (usada)
- Amazon: R$ 120-150 (nova)
- AliExpress: R$ 60-90 (demora 30+ dias)

**Resultado esperado:**
- Scans 2-3x mais rápidos
- Menos swapping (sistema não trava)
- Pode rodar múltiplas ferramentas simultaneamente

---

### **🟠 PRIORIDADE 2 - Switch Gigabit**
**Custo:** R$ 150-250  
**Impacto:** ⭐⭐⭐⭐☆ (ALTO)  
**Tempo de instalação:** 10 minutos

**Por quê:**
- ✅ Hub 10/100 atual = **10x mais lento** que Gigabit
- ✅ Transferência de VMs/dados demora eternamente
- ✅ Scans internos limitados a 100Mbps

**Modelos recomendados:**
| Modelo | Portas | Preço | Onde |
|--------|--------|-------|------|
| TP-Link TL-SG108 | 8x Gigabit | ~R$ 150 | ML/Amazon |
| TP-Link TL-SG105 | 5x Gigabit | ~R$ 120 | ML/Amazon |
| D-Link DGS-1008A | 8x Gigabit | ~R$ 180 | Amazon |

**Resultado esperado:**
- Transferências 10x mais rápidas (100MB → 1000MB/s)
- Scans internos mais eficientes
- Melhor para pivoting entre máquinas

---

### **🟡 PRIORIDADE 3 - PC1: NVMe Adicional**
**Custo:** R$ 200-350  
**Impacto:** ⭐⭐⭐☆☆ (MÉDIO)  
**Tempo de instalação:** 15-30 minutos

**Por quê:**
- ✅ NVMe 256GB atual = OS + 1-2 VMs
- ✅ Precisa de NVMe dedicado para VMs (performance)
- ✅ SSD SATA para storage de ISOs/backups

**Opções:**
| Capacidade | Modelo Exemplo | Preço | Performance |
|------------|----------------|-------|-------------|
| 512GB | Kingston NV2 | ~R$ 250 | 3500MB/s read |
| 1TB | WD Blue SN580 | ~R$ 400 | 4000MB/s read |
| 512GB | Crucial P3 | ~R$ 280 | 3500MB/s read |

**Recomendação:** 512GB Kingston NV2 (melhor custo-benefício)

**Como usar:**
```bash
# Configurar no Proxmox:
# 1. NVMe1 (atual): Proxmox OS
# 2. NVMe2 (novo): Armazenamento de VMs prioritárias
# 3. SSD SATA: ISOs, templates, backups
```

**Resultado esperado:**
- 2-3 VMs rodando sem lag
- Boot de VMs 2x mais rápido
- Melhor distribuição de I/O

---

### **🟢 PRIORIDADE 4 - PC2: Trocar Completo**
**Custo:** R$ 800-1500 (usado) | R$ 2000-3000 (novo)  
**Impacto:** ⭐⭐⭐⭐⭐ (MUITO ALTO a longo prazo)  
**Tempo de instalação:** 2-3 horas (setup completo)

**Por quê:**
- ✅ i5-3330 tem **12 anos** (2012)
- ✅ DDR3 descontinuada (cara e difícil de achar)
- ✅ Sem suporte AVX2 (algumas ferramentas modernas não rodam)

**Opções de upgrade:**

#### **Opção A: Usado (Melhor custo-benefício)**
```
CPU: i5-8400 ou i5-9400 (6 cores, 6ª-9ª geração)
RAM: 16GB DDR4
Storage: SSD 256GB (aproveitar atual)
Mobo: H310 ou B365

Preço total: R$ 800-1200
Onde: Mercado Livre, OLX, Hardmob
```

#### **Opção B: Novo Entry-Level**
```
CPU: i3-12100F ou Ryzen 5 5600G
RAM: 16GB DDR4 3200MHz
Storage: SSD 512GB NVMe
Mobo: H610 ou B450

Preço total: R$ 1800-2500
Onde: Pichau, Kabum, Terabyte
```

#### **Opção C: Upgrade PC1 → PC2**
```
1. Comprar PC novo para Proxmox (PC1)
2. PC1 atual (i5-12400F) vira novo PC2
3. PC2 atual (i5-3330) vira backup/testes
```

**Resultado esperado:**
- Performance 3-4x melhor em scans
- Suporte a ferramentas modernas
- Vida útil de +5-7 anos

---

## 💰 **Orçamento por Cenário**

### **Cenário 1: Mínimo Viável (R$ 100-150)**
```
✅ +8GB RAM no PC2

Resultado:
- PC2 funcional para scans médios
- Ainda com CPU antiga
- Resolve gargalo imediato
```

---

### **Cenário 2: Ótimo Custo-Benefício (R$ 350-500)**
```
✅ +8GB RAM no PC2         (R$ 120)
✅ Switch Gigabit 8 portas (R$ 180)
✅ HD externo 1TB backup   (R$ 200)

Resultado:
- PC2 funcional
- Lab com rede rápida
- Backups seguros
```

---

### **Cenário 3: Upgrade Completo (R$ 1200-1800)**
```
✅ +8GB RAM no PC2         (R$ 120)
✅ Switch Gigabit          (R$ 180)
✅ NVMe 512GB para PC1     (R$ 280)
✅ PC usado i5-8400/16GB   (R$ 800)
   (substituir PC2)

Resultado:
- Setup profissional completo
- Sem gargalos
- Duradouro (+5 anos)
```

---

## 🛠️ **Ordem Recomendada de Upgrade**

### **Fase 1: Imediato (1-2 semanas)**
1. ✅ Comprar +8GB RAM DDR3 para PC2
2. ✅ Instalar e testar
3. ✅ Benchmark antes/depois

### **Fase 2: Curto Prazo (1-2 meses)**
4. ✅ Comprar Switch Gigabit
5. ✅ Reorganizar rede
6. ✅ Testar transferências

### **Fase 3: Médio Prazo (3-6 meses)**
7. ✅ Comprar NVMe adicional para PC1
8. ✅ Migrar VMs para novo storage
9. ✅ Otimizar Proxmox

### **Fase 4: Longo Prazo (6-12 meses)**
10. ✅ Juntar R$ 800-1200
11. ✅ Comprar PC usado i5-8400/16GB
12. ✅ Migrar PC2 para novo hardware
13. ✅ PC2 antigo vira máquina de testes

---

## 📊 **Comparativo de Performance**

### **Scans Nmap (1000 IPs, -T4)**

| Hardware | Tempo | RAM Usada |
|----------|-------|-----------|
| PC2 atual (8GB) | ~15 min | 6.5GB (swapping) |
| PC2 + 8GB RAM | ~12 min | 10GB (confortável) |
| PC novo (i5-8400/16GB) | ~6 min | 8GB (rápido) |

### **Metasploit (iniciar framework)**

| Hardware | Tempo de Boot |
|----------|---------------|
| PC2 atual | ~45 segundos |
| PC2 + 8GB RAM | ~30 segundos |
| PC novo | ~15 segundos |

---

## 🔍 **Como Verificar Compatibilidade**

### **RAM**
```bash
# No PC2 (Linux)
sudo dmidecode --type memory | grep -E "Type:|Speed:|Size:|Locator:"

# Verificar slots livres
sudo dmidecode -t memory | grep "Number Of Devices"
```

### **NVMe**
```bash
# No PC1 (Proxmox)
lspci | grep -i nvme

# Ver slots M.2 disponíveis (verificar placa-mãe)
sudo dmidecode -t baseboard
```

---

## 📝 **Checklist Pré-Compra**

### **RAM**
- [ ] Verificar tipo (DDR3/DDR4)
- [ ] Verificar frequência (MHz)
- [ ] Verificar slots livres
- [ ] Comprar da mesma marca (ideal)

### **Switch**
- [ ] Verificar portas necessárias (5, 8, 16?)
- [ ] Confirmar Gigabit (10/100/1000)
- [ ] Ler reviews (confiabilidade)

### **NVMe**
- [ ] Verificar slot M.2 na placa-mãe
- [ ] Confirmar suporte NVMe (não SATA M.2)
- [ ] Verificar espaço físico no gabinete

### **PC Usado**
- [ ] Testar antes de comprar
- [ ] Verificar BIOS/POST
- [ ] Stress test (Prime95, Memtest)
- [ ] Verificar temperatura

---

## 💡 **Dicas de Economia**

1. **Comprar usado em fóruns confiáveis:**
   - Hardmob (fórum brasileiro de hardware)
   - Grupo Facebook "Peças de PC Usadas"
   - OLX (verificar vendedor)

2. **Black Friday / Cyber Monday:**
   - RAM e SSDs costumam ter 30-40% desconto

3. **Upgrade incremental:**
   - RAM primeiro (maior impacto)
   - Switch depois
   - NVMe só se realmente necessário

4. **Vender hardware antigo:**
   - PC2 atual pode valer R$ 300-400
   - Ajuda a pagar upgrade

---

## 🎯 **ROI (Retorno sobre Investimento)**

| Upgrade | Custo | Tempo Economizado | ROI |
|---------|-------|-------------------|-----|
| +8GB RAM | R$ 120 | ~2h/semana (scans mais rápidos) | 🟢 Alto |
| Switch Gigabit | R$ 180 | ~1h/semana (transferências) | 🟢 Alto |
| NVMe adicional | R$ 280 | ~30min/semana (VMs) | 🟡 Médio |
| PC novo | R$ 1000 | ~5h/semana (performance geral) | 🟢 Alto |

---

**Última atualização:** 2025-11-28  
**Autor:** Samuel Ziger

**Lembre-se:** Upgrade de RAM primeiro = maior retorno!
