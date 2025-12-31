# ===================================================================
#  SCRIPT DE REVERSAO - DESFAZ BLOQUEIO APLICADO POR bloqueioAPP.bat
# ===================================================================

# Verificar se está executando como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERRO: Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "Clique com botao direito no arquivo e selecione 'Executar como Administrador'" -ForegroundColor Yellow
    Read-Host "Pressione Enter para sair"
    exit
}

# Configurar console
$Host.UI.RawUI.WindowTitle = "DESBLOQUEIO - REVERTER BLOQUEIO TOTAL"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Yellow"
Clear-Host

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   PREVIEW: ACOES QUE SERAO EXECUTADAS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script ira DESFAZER as seguintes configuracoes:" -ForegroundColor White
Write-Host ""
Write-Host "[1/7] Remover bloqueio de downloads" -ForegroundColor Green
Write-Host "      - Restaurar politica de anexos" -ForegroundColor Gray
Write-Host ""
Write-Host "[2/7] Remover regras de Firewall para launchers" -ForegroundColor Green
Write-Host "      - Steam" -ForegroundColor Gray
Write-Host "      - Epic Games" -ForegroundColor Gray
Write-Host "      - Riot Client" -ForegroundColor Gray
Write-Host "      - Battle.net" -ForegroundColor Gray
Write-Host "      - Garena" -ForegroundColor Gray
Write-Host "      - Minecraft Launcher" -ForegroundColor Gray
Write-Host ""
Write-Host "[3/7] Remover bloqueio de sites do arquivo hosts" -ForegroundColor Green
Write-Host "      - store.steampowered.com" -ForegroundColor Gray
Write-Host "      - steamcommunity.com" -ForegroundColor Gray
Write-Host "      - epicgames.com" -ForegroundColor Gray
Write-Host "      - riotgames.com" -ForegroundColor Gray
Write-Host "      - battle.net" -ForegroundColor Gray
Write-Host "      - roblox.com" -ForegroundColor Gray
Write-Host "      - minecraft.net" -ForegroundColor Gray
Write-Host "      - garena.com" -ForegroundColor Gray
Write-Host "      - mediafire.com" -ForegroundColor Gray
Write-Host "      - mega.nz" -ForegroundColor Gray
Write-Host "      - tlauncher.org" -ForegroundColor Gray
Write-Host "      - uptodown.com" -ForegroundColor Gray
Write-Host "      - baixaki.com.br" -ForegroundColor Gray
Write-Host ""
Write-Host "[4/7] Remover Software Restriction Policy" -ForegroundColor Green
Write-Host "      - Remover bloqueios de pastas (Downloads, Desktop, AppData)" -ForegroundColor Gray
Write-Host ""
Write-Host "[5/7] Remover bloqueio de instaladores" -ForegroundColor Green
Write-Host "      - Desbloquear setup.exe, install.exe, launcher.exe, etc" -ForegroundColor Gray
Write-Host ""
Write-Host "[6/7] Desbloquear pendrive" -ForegroundColor Green
Write-Host "      - Remover politica de bloqueio de dispositivos removiveis" -ForegroundColor Gray
Write-Host ""
Write-Host "[7/7] Aplicar politicas" -ForegroundColor Green
Write-Host "      - Executar gpupdate /force" -ForegroundColor Gray
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   ATENCAO: Isso revertera TODAS as restricoes!" -ForegroundColor Red
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Digite 'SIM' e pressione Enter para CONFIRMAR e EXECUTAR..." -ForegroundColor Yellow
Write-Host "Ou digite 'NAO' ou feche esta janela para CANCELAR." -ForegroundColor Yellow
Write-Host ""

$confirmacao = Read-Host "Confirmar execucao? (SIM/NAO)"

if ($confirmacao -ne "SIM") {
    Write-Host ""
    Write-Host "Operacao CANCELADA pelo usuario." -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

Clear-Host
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   EXECUTANDO DESBLOQUEIO..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------
# 1. DESBLOQUEAR DOWNLOADS
# ---------------------------------------------------
Write-Host "[1/7] Desbloqueando downloads..." -ForegroundColor Green
try {
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -Name "ScanWithAntiVirus" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -Name "SaveZoneInformation" -ErrorAction SilentlyContinue
    Write-Host "  Downloads desbloqueados!" -ForegroundColor DarkGreen
} catch {
    Write-Host "  Aviso: Erro ao desbloquear downloads - $_" -ForegroundColor DarkYellow
}

# ---------------------------------------------------
# 2. FIREWALL – DESBLOQUEAR LAUNCHERS
# ---------------------------------------------------
Write-Host "[2/7] Removendo regras de bloqueio do Firewall..." -ForegroundColor Green

$launchers = @(
    "C:\Program Files (x86)\Steam\steam.exe",
    "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe",
    "C:\Riot Games\Riot Client\RiotClientServices.exe",
    "C:\Program Files (x86)\Battle.net\Battle.net.exe",
    "C:\Program Files (x86)\Garena\Garena\Garena.exe",
    "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"
)

foreach ($launcher in $launchers) {
    try {
        netsh advfirewall firewall delete rule name="Bloqueio $launcher" 2>$null | Out-Null
        Write-Host "  Desbloqueado: $launcher" -ForegroundColor DarkGreen
    } catch {
        Write-Host "  Aviso: $launcher - regra nao encontrada" -ForegroundColor DarkYellow
    }
}

# ---------------------------------------------------
# 3. DESBLOQUEAR SITES (REMOVER DO HOSTS)
# ---------------------------------------------------
Write-Host "[3/7] Removendo bloqueios de sites do arquivo hosts..." -ForegroundColor Green

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$sites = @(
    "store.steampowered.com",
    "steamcommunity.com",
    "epicgames.com",
    "riotgames.com",
    "battle.net",
    "roblox.com",
    "minecraft.net",
    "garena.com",
    "mediafire.com",
    "mega.nz",
    "tlauncher.org",
    "uptodown.com",
    "baixaki.com.br"
)

try {
    # Criar backup
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Copy-Item $hostsPath "$hostsPath.backup_$timestamp" -ErrorAction SilentlyContinue
    
    # Ler arquivo hosts e remover linhas bloqueadas
    $hostsContent = Get-Content $hostsPath
    $newHostsContent = $hostsContent | Where-Object { 
        $line = $_
        $shouldKeep = $true
        foreach ($site in $sites) {
            if ($line -match "127\.0\.0\.1\s+$site") {
                $shouldKeep = $false
                Write-Host "  Site desbloqueado: $site" -ForegroundColor DarkGreen
                break
            }
        }
        $shouldKeep
    }
    
    Set-Content -Path $hostsPath -Value $newHostsContent -Force
    Write-Host "  Arquivo hosts limpo!" -ForegroundColor DarkGreen
} catch {
    Write-Host "  Aviso: Erro ao modificar hosts - $_" -ForegroundColor DarkYellow
}

# ---------------------------------------------------
# 4. REMOVER SOFTWARE RESTRICTION POLICY
# ---------------------------------------------------
Write-Host "[4/7] Removendo regras de Software Restriction Policy..." -ForegroundColor Green

try {
    # Remover DefaultLevel
    Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" -Name "DefaultLevel" -ErrorAction SilentlyContinue
    
    # Remover todas as paths criadas (IDs 26200-26210)
    for ($i = 26200; $i -le 26210; $i++) {
        Remove-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers\Paths\$i" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "  Regras de restricao removidas!" -ForegroundColor DarkGreen
} catch {
    Write-Host "  Aviso: Erro ao remover SRP - $_" -ForegroundColor DarkYellow
}

# ---------------------------------------------------
# 5. DESBLOQUEAR INSTALADORES
# ---------------------------------------------------
Write-Host "[5/7] Desbloqueando instaladores..." -ForegroundColor Green
Write-Host "  (Ja removidos junto com Software Restriction Policy)" -ForegroundColor DarkGreen

# ---------------------------------------------------
# 6. DESBLOQUEAR PEN-DRIVE
# ---------------------------------------------------
Write-Host "[6/7] Desbloqueando pendrive..." -ForegroundColor Green

try {
    Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\RemovableStorageDevices" -Name "Deny_All" -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\RemovableStorageDevices" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Pendrive desbloqueado!" -ForegroundColor DarkGreen
} catch {
    Write-Host "  Aviso: Erro ao desbloquear pendrive - $_" -ForegroundColor DarkYellow
}

# ---------------------------------------------------
# 7. APLICAR POLÍTICAS
# ---------------------------------------------------
Write-Host "[7/7] Aplicando politicas..." -ForegroundColor Green
try {
    gpupdate /force 2>&1 | Out-Null
    Write-Host "  Politicas aplicadas!" -ForegroundColor DarkGreen
} catch {
    Write-Host "  Aviso: Erro ao aplicar politicas - $_" -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DESBLOQUEIO CONCLUIDO COM SUCESSO!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Todas as restricoes do bloqueioAPP.bat foram removidas." -ForegroundColor White
Write-Host "Backup do arquivo hosts criado em:" -ForegroundColor White
Write-Host "$env:SystemRoot\System32\drivers\etc\hosts.backup_*" -ForegroundColor Gray
Write-Host ""
Write-Host "Pressione qualquer tecla para finalizar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
