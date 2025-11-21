# Windows - Scripts de Setup

## 📋 Visão Geral

Conjunto de scripts para configuração automatizada de ambiente Windows para Penetration Testing e Red Team Operations.

---

## 📁 Arquivos Disponíveis

### **Scripts Principais**

| Script | Descrição | Hardware Alvo | Uso |
|--------|-----------|---------------|-----|
| `atack2.0-optimized.bat` | **Setup Notebook 2** - Attack Box AD/Lateral Movement **(RECOMENDADO)** | i5-3210M / 12GB | Execute como admin |
| `setup-attackbox.ps1` | Setup PowerShell genérico | Qualquer PC | Via `setup_attackbox.bat` |
| `setup_attackbox.bat` | Launcher para o script PowerShell | Qualquer PC | Clique duplo |
| `atack2.0.bat` | Setup completo com WSL2 + Kali (versão original) | Qualquer PC | Execute como admin |

**📖 Guia específico do Notebook 2**: Veja [NOTEBOOK2-GUIDE.md](./NOTEBOOK2-GUIDE.md)

### **Scripts Auxiliares**

| Script | Descrição |
|--------|-----------|
| `rollback.bat` | **NOVO!** Reverte todas as configurações do setup |
| `verificao.bat` | Verifica se o setup foi bem-sucedido |
| `setup-debug.bat` | Modo debug para troubleshooting |
| `bloqueioAPP.bat` | Bloqueio de aplicativos (para ambientes escolares/corporativos) |

### **Scripts Descontinuados**

- `SetupAtack.bat` - Substituído por `atack2.0.bat`
- `SetupAtack2.bat` - Substituído por `atack2.0.bat`

---

## 🚀 Como Usar

### **Setup Completo (Método Recomendado)**

1. **Clique com botão direito** em `setup_attackbox.bat`
2. Selecione **"Executar como administrador"**
3. Aguarde a conclusão (pode demorar 30-60 minutos)
4. Reinicie o sistema

### **Verificação Pós-Instalação**

```cmd
.\verificao.bat
```

Verifica:
- ✅ Status do Windows Defender
- ✅ Serviço SSH
- ✅ Chocolatey instalado
- ✅ Ferramentas (Nmap, Python, Git, etc.)
- ✅ WSL2 + Kali Linux
- ✅ Perfil PowerShell
- ✅ Modo de energia

### **Modo Debug**

Se o setup travar ou falhar:

```cmd
.\setup-debug.bat
```

Este modo mantém a janela aberta e mostra todos os erros.

### **Rollback / Reverter Configurações**

Para desfazer todas as alterações do setup:

```cmd
.\rollback.bat
```

**O que será revertido:**
- Reativa Windows Defender
- Restaura ExecutionPolicy para Restricted
- Remove exclusões de segurança
- Reativa serviços do Windows (WSearch, DiagTrack)
- Restaura plano de energia balanceado
- **(Opcional)** Remove ferramentas instaladas

---

## 🛠️ Ferramentas Instaladas

### **Via Chocolatey**
- Git
- Python
- Ruby
- Nmap
- Wireshark
- Sysinternals Suite
- 7-Zip
- VS Code
- JQ
- OpenSSH

### **Ferramentas AD (Active Directory)**
```
C:\Tools\AD\
├── Bloodhound\          # GUI para análise de AD
├── SharpHound\          # Coletor de dados AD
└── Powerview\           # Scripts PowerShell para enum AD
```

### **Post-Exploitation**
```
C:\Tools\PostEx\
├── Rubeus\              # Kerberos attacks
├── Seatbelt\            # Enumeration de segurança
├── WinPEAS\             # Privilege escalation
├── SharpUp\             # Privilege escalation checker
└── SharpMapExec\        # Lateral movement
```

### **Payloads**
```
C:\Tools\Payloads\
├── Office\              # Payloads Office (macro, etc.)
├── HTA\                 # HTML Applications
├── MSI\                 # Instaladores maliciosos
├── EXE\                 # Executáveis
├── ScareCrow\           # Payload obfuscation
├── Nimcrypt2\           # .NET encryptor
└── donut\               # Shellcode generator
```

### **Outras Ferramentas**
```
C:\Tools\Tools\
├── impacket\            # Suite Python para protocolos de rede
├── evilwinrm\           # WinRM shell (via Ruby gem)
├── sysinternals\        # Suite Sysinternals
└── mimikatz\            # (Baixar manualmente)
```

---

## ⚙️ Configurações Aplicadas

### **Segurança (ATENÇÃO!)**

⚠️ **Estas configurações deixam o sistema VULNERÁVEL. Use apenas em VMs isoladas!**

- Windows Defender **desativado**
- SmartScreen **desativado**
- Exclusões em `C:\Tools` e `C:\AttackBox`
- ExecutionPolicy: **Unrestricted**

### **Performance**

- Plano de energia: **Alto desempenho**
- Hibernação: **Desativada**
- Serviços desnecessários desativados:
  - DiagTrack (telemetria)
  - WSearch (indexação)
  - RetailDemo

### **Desenvolvimento**

- **SSH Server** habilitado e rodando na porta 22
- **WSL2** instalado com Kali Linux
- **Perfil PowerShell** customizado com aliases:
  ```powershell
  ll    → ls
  la    → ls -Force
  grep  → Select-String
  wget  → curl
  cat   → Get-Content
  ```

---

## 🐛 Troubleshooting

### **Erro: "Execution of scripts is disabled"**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### **Chocolatey não encontrado após instalação**

```cmd
refreshenv
# ou reinicie o terminal
```

### **Downloads falham ou arquivos corrompidos**

1. Verifique sua conexão com internet
2. Execute novamente - agora tem verificação de arquivos já baixados
3. Delete manualmente a pasta e tente novamente:
   ```powershell
   Remove-Item C:\Tools\<pasta> -Recurse -Force
   ```

### **WSL2 não instala**

1. Certifique-se que virtualização está habilitada na BIOS/UEFI
2. Execute:
   ```powershell
   wsl --update
   wsl --set-default-version 2
   ```
3. Reinicie o sistema
4. Execute novamente: `wsl --install -d kali-linux`

### **Git clone falha (pasta já existe)**

Os scripts agora verificam se a pasta `.git` existe antes de clonar. Se ainda assim falhar:

```powershell
Remove-Item C:\Tools\<pasta> -Recurse -Force
```

---

## 📊 Melhorias Implementadas (v2.0)

✅ **Verificação de arquivos existentes** - Não baixa/clona se já existir  
✅ **Mensagens informativas** - Mostra quando pula download  
✅ **Script de rollback** - Reverte todas as configurações  
✅ **Melhor tratamento de erros** - Menos falhas em execuções repetidas

---

## ⚠️ Avisos Importantes

1. **Use apenas em VMs isoladas** - Nunca em sistema de produção
2. **Desativa proteções críticas** - Sistema fica vulnerável
3. **Requer 20GB+ de espaço livre**
4. **Conexão de internet obrigatória**
5. **Execução pode demorar 30-60 minutos**

---

## 🔄 Ordem Recomendada de Execução

1. `setup_attackbox.bat` (ou `atack2.0.bat`)
2. **Reiniciar sistema**
3. `verificao.bat` (confirmar instalação)
4. Começar a usar as ferramentas
5. `rollback.bat` (quando terminar de usar)

---

## 📚 Recursos Adicionais

- [Documentação Impacket](https://github.com/fortra/impacket)
- [BloodHound Documentation](https://bloodhound.readthedocs.io/)
- [PEASS-ng Wiki](https://github.com/carlospolop/PEASS-ng)
- [HackTricks](https://book.hacktricks.xyz/)

---

**Última atualização:** Novembro 2025
