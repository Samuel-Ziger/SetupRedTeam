# Windows - Scripts de Setup

## 📋 Visão Geral

Conjunto de scripts para configuração automatizada de ambiente Windows para Penetration Testing e Red Team Operations.

### 🎯 Análise do Repositório Windows

**Estatísticas:**
- **Scripts totais:** 18 arquivos
- **Scripts principais:** 4 (atack2.0-optimized.bat, setup-attackbox.ps1, atack2.0.bat, rollback.bat)
- **Scripts auxiliares:** 10 (verificação, debug, bloqueios)
- **Documentação:** 2 (README.md, NOTEBOOK2-GUIDE.md)
- **Scripts descontinuados:** 2 (SetupAtack.bat, SetupAtack2.bat)
- **Linguagens:** Batch (.bat), PowerShell (.ps1)

**Novidades (v2.0):**
- ✅ **atack2.0-optimized.bat** - Otimizado para Notebook 2 (i5-3210M, 12GB) focado em AD/Lateral Movement
- ✅ **rollback.bat** - Reverter todas as configurações de segurança
- ✅ **NOTEBOOK2-GUIDE.md** - Guia completo de 400+ linhas com workflows práticos
- ✅ **Verificação de duplicatas** - Scripts não baixam/clonam ferramentas já existentes
- ✅ **Melhor tratamento de erros** - Mensagens informativas em português

**Foco Especializado:**
- 🎯 **Active Directory:** BloodHound, SharpHound, Rubeus, PowerView, Certify
- 🎯 **Lateral Movement:** Evil-WinRM, Impacket, CrackMapExec (via WSL2)
- 🎯 **Post-Exploitation:** Seatbelt, WinPEAS, SharpUp, SharpDPAPI
- 🎯 **Payload Evasion:** Donut, ScareCrow, Nimcrypt2

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
|--------|-----------||
| `rollback.bat` | **NOVO!** Reverte todas as configurações do setup |
| `verificao.bat` | Verifica se o setup foi bem-sucedido |
| `setup-debug.bat` | Modo debug para troubleshooting |
| `bloqueioAPP.bat` | Bloqueio de aplicativos (para ambientes escolares/corporativos) |
| `BloqueioGeral.bat` | Bloqueio geral de recursos do sistema |
| `Bloqueiojogos.bat` | Bloqueio específico de jogos e entretenimento |
| `DesbloqueioCompleto.bat` | Remove todos os bloqueios aplicados |
| `DesfazBloqueioAPP.bat` | Remove bloqueio de aplicativos específicos |
| `DesfazBloqueioAPP.ps1` | Versão PowerShell do desbloqueio |
| `desfazer_geral.bat` | Remove bloqueio geral do sistema |

**⚠️ Nota sobre Scripts de Bloqueio:**
Os scripts de bloqueio (`bloqueioAPP.bat`, `BloqueioGeral.bat`, etc.) foram criados para ambientes controlados (escolas, laboratórios) e **NÃO** fazem parte do setup de Attack Box. Use apenas se necessário para controle de acesso.

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

### **📦 Via Chocolatey (Gerenciador de Pacotes)**
| Ferramenta | Descrição | Uso |
|------------|-----------|-----|
| **Git** | Sistema de controle de versão | Clone de ferramentas, versionamento |
| **Python** | Linguagem de programação | Impacket, scripts custom |
| **Ruby** | Linguagem de programação | Evil-WinRM (gem install) |
| **Nmap** | Network scanner | Port scanning, service enumeration |
| **Wireshark** | Packet analyzer | Traffic analysis, protocol debugging |
| **Sysinternals Suite** | Utilities Windows | PsExec, ProcMon, Process Explorer |
| **7-Zip** | File archiver | Extração de payloads, compressão |
| **VS Code** | Editor de código | Script editing, development |
| **JQ** | JSON processor | Parse outputs de ferramentas |
| **OpenSSH** | SSH client/server | Remote access, tunneling |

### **🎯 Ferramentas AD (Active Directory)**
```
C:\Tools\AD\
├── Bloodhound\          # Análise gráfica de relações AD
│   ├── BloodHound.exe   # GUI principal
│   └── Neo4j database   # Graph database
│
├── SharpHound\          # Coletor de dados AD (C#)
│   └── SharpHound.exe   # Executável standalone
│
└── Powerview\           # Scripts PowerShell para enum AD
    └── PowerView.ps1    # Módulo PowerShell
```

**Descrições Detalhadas:**

- **BloodHound:** Ferramenta gráfica que usa teoria de grafos para revelar relações ocultas em Active Directory. Identifica caminhos de ataque (attack paths) de usuários de baixo privilégio até Domain Admins.
  
- **SharpHound:** Coletor de dados (ingestor) para BloodHound. Faz enumeração massiva de AD (usuários, grupos, GPOs, ACLs, sessions) e exporta para JSON.

- **PowerView:** Suite PowerShell para enumeração e exploitation de AD. Funções para encontrar usuários privilegiados, shares acessíveis, GPOs mal configuradas, etc.

### **💣 Post-Exploitation**
```
C:\Tools\PostEx\
├── Rubeus\              # Kerberos attacks (C#)
│   └── Rubeus.exe       # Kerberoasting, AS-REP roasting, Golden/Silver tickets
│
├── Seatbelt\            # Enumeration de segurança (C#)
│   └── Seatbelt.exe     # Security posture checker
│
├── WinPEAS\             # Privilege escalation automation
│   └── winPEASx64.exe   # PE enumeration + exploit suggester
│
├── SharpUp\             # Privilege escalation checker (C#)
│   └── SharpUp.exe      # Misconfiguration finder
│
├── SharpMapExec\        # Lateral movement (C#)
│   └── SharpMapExec.exe # WMI/SMB lateral movement
│
├── Certify\             # AD Certificate Services exploitation
│   └── Certify.exe      # Find vulnerable certificate templates
│
└── SharpDPAPI\          # DPAPI credential extractor
    └── SharpDPAPI.exe   # Chrome/Edge/RDP credential dumping
```

**Descrições Detalhadas:**

- **Rubeus:** Toolkit completo para ataques Kerberos. Kerberoasting (extract TGS), AS-REP roasting, Pass-the-Ticket, Golden/Silver ticket creation.

- **Seatbelt:** Enumera configurações de segurança do Windows (antivirus, AppLocker, LAPS, credential guard, autologon, etc.). Essencial para situational awareness.

- **WinPEAS:** Script automatizado que procura vulnerabilidades de privilege escalation. Verifica unquoted service paths, weak permissions, scheduled tasks, registry keys, etc.

- **SharpUp:** Similar ao WinPEAS mas focado em C#. Checa AlwaysInstallElevated, services, DLL hijacking, modifiable binaries.

- **SharpMapExec:** Execução lateral de comandos via WMI/SMB. Alternative ao PsExec/WMI diretamente.

- **Certify:** Explora AD Certificate Services (ADCS) mal configurados. Encontra templates vulneráveis que permitem privilege escalation.

- **SharpDPAPI:** Extrai credenciais armazenadas via DPAPI (browsers, RDP, wireless networks). Requer privilégios do usuário alvo.

### **🚀 Payloads & Evasion**
```
C:\Tools\Payloads\
├── Office\              # Payloads Office (VBA macros, etc.)
├── HTA\                 # HTML Applications (mshta.exe)
├── MSI\                 # Instaladores maliciosos
├── EXE\                 # Executáveis compilados
│
├── ScareCrow\           # Payload obfuscation com EDR evasion
│   └── ScareCrow.exe    # .NET/shellcode -> obfuscated loader
│
├── Nimcrypt2\           # .NET executable encryptor
│   └── Nimcrypt2.exe    # AES encryption + Nim loader
│
└── donut\               # Shellcode generator
    └── donut.exe        # .NET assembly -> position-independent shellcode
```

**Descrições Detalhadas:**

- **Donut:** Converte .NET assemblies (EXE/DLL) em shellcode position-independent. Permite injetar ferramentas C# (Rubeus, Seatbelt) diretamente em processos via process injection.

- **ScareCrow:** Obfuscador de payloads com evasão de EDR. Usa técnicas como syscalls diretos, API unhooking, encryption. Suporta shellcode e executáveis.

- **Nimcrypt2:** Encripta executáveis .NET usando AES e cria loader em Nim (linguagem menos detectada por AVs). Bypass de assinaturas estáticas.

### **🌐 Networking & Lateral Movement**
```
C:\Tools\Tools\
├── impacket\            # Suite Python para protocolos de rede Windows
│   ├── psexec.py        # Remote command execution via SMB
│   ├── smbexec.py       # Stealthier psexec alternative
│   ├── wmiexec.py       # WMI-based remote execution
│   ├── secretsdump.py   # Dump NTLM hashes/LSA secrets
│   ├── GetUserSPNs.py   # Kerberoasting
│   ├── GetNPUsers.py    # AS-REP roasting
│   └── ntlmrelayx.py    # NTLM relay attacks
│
├── evilwinrm\           # WinRM shell (Ruby gem)
│   └── evil-winrm       # Interactive PowerShell over WinRM
│
└── sysinternals\        # Sysinternals Suite
    ├── PsExec.exe       # Remote execution
    ├── ProcMon.exe      # Process monitoring
    ├── TCPView.exe      # Network connections viewer
    └── ...
```

**Descrições Detalhadas:**

- **Impacket:** Suite Python que implementa protocolos de rede Windows (SMB, MSRPC, Kerberos). Ferramentas essenciais para lateral movement, credential dumping e exploitation.

- **Evil-WinRM:** Shell interativa via WinRM (Windows Remote Management). Suporta upload/download de arquivos, load de scripts PowerShell, pass-the-hash.

- **Sysinternals:** Coleção de utilitários oficiais da Microsoft para troubleshooting e análise. PsExec para execução remota, ProcMon para monitorar processos/registry.

### **🐧 WSL2 + Kali Linux**

O script instala **WSL2** com **Kali Linux** completo, permitindo usar ferramentas Linux diretamente no Windows:

```bash
# Ferramentas instaladas no Kali via WSL2:
wsl -d kali-linux

# CrackMapExec (lateral movement suite)
crackmapexec smb 192.168.1.0/24 -u admin -p password

# Metasploit Framework
msfconsole

# Nmap (versão Linux)
nmap -sC -sV target.com
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
