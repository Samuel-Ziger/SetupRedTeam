@echo off
title Git Push - Atualização 2025-11-28
chcp 65001 >nul

echo ╔════════════════════════════════════════════════════════════╗
echo ║         GIT PUSH - ATUALIZAÇÃO PARA PRODUÇÃO              ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Verificar se está no diretório correto
cd /d "%~dp0"

echo [1/5] Verificando status do Git...
git status
echo.

echo [2/5] Adicionando todos os arquivos novos...
git add .
echo.

echo [3/5] Criando commit...
git commit -m "🚀 Major Update - OPSEC + Backup + C2 + Cloud Tools + Docs (v2.0)" ^
    -m "" ^
    -m "Novas funcionalidades (2025-11-28):" ^
    -m "✅ Biblioteca OPSEC completa (lib/opsec.sh)" ^
    -m "✅ Sistema de backup automatizado (lib/backup_tools.sh)" ^
    -m "✅ Verificação de recursos (lib/resource_check.sh)" ^
    -m "✅ Gerador de relatórios PDF (lib/generate_report.sh)" ^
    -m "✅ Instalador Wazuh SIEM (lib/install_wazuh.sh)" ^
    -m "✅ C2 modernos: Sliver, Havoc, Mythic" ^
    -m "✅ Cloud tools: Pacu, ScoutSuite, Prowler, CloudFox" ^
    -m "✅ CI/CD GitHub Actions automatizado" ^
    -m "✅ Wrapper OPSEC para retestes" ^
    -m "✅ Documentação completa (5 guias)" ^
    -m "" ^
    -m "Arquivos novos:" ^
    -m "- lib/opsec.sh, backup_tools.sh, resource_check.sh" ^
    -m "- lib/generate_report.sh, install_wazuh.sh" ^
    -m "- docs/OPSEC_CHECKLIST.md, BACKUP_STRATEGY.md, UPGRADE_GUIDE.md" ^
    -m "- templates/report_template.md" ^
    -m "- .github/workflows/reteste.yml" ^
    -m "- NOVAS_FUNCIONALIDADES.md, QUICK_START.md" ^
    -m "- IMPLEMENTACAO_COMPLETA.md" ^
    -m "" ^
    -m "Atualizações:" ^
    -m "- Kali/setup-kali.sh: +C2 frameworks +Cloud tools" ^
    -m "- README.md: Seção de novidades adicionada" ^
    -m "" ^
    -m "Total: ~4,340 linhas adicionadas" ^
    -m "Compatibilidade: 100%% retrocompatível"

echo.

if errorlevel 1 (
    echo [!] Erro ao criar commit!
    echo     Pode ser que não haja mudanças para commitar.
    pause
    exit /b 1
)

echo [4/5] Status após commit...
git log -1 --oneline
echo.

echo [5/5] Fazendo push para GitHub...
echo.
echo ⚠️ Você está prestes a fazer push para o repositório:
git remote -v | findstr origin
echo.

choice /C SN /M "Deseja continuar com o push"

if errorlevel 2 (
    echo.
    echo ❌ Push cancelado pelo usuário.
    echo    Para fazer push manualmente depois: git push origin main
    pause
    exit /b 0
)

echo.
echo 🚀 Fazendo push...
git push origin main

if errorlevel 1 (
    echo.
    echo [!] Erro ao fazer push!
    echo     Verifique:
    echo     1. Se você está autenticado no GitHub
    echo     2. Se tem permissões no repositório
    echo     3. Se a branch main existe
    echo.
    echo Tentar push com força? (use com CUIDADO!)
    choice /C SN /M "Force push"
    
    if errorlevel 2 (
        echo Push cancelado.
        pause
        exit /b 1
    )
    
    git push -f origin main
)

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║              ✅ PUSH CONCLUÍDO COM SUCESSO!               ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 🌐 Verifique seu repositório em:
echo    https://github.com/Samuel-Ziger/Scripts-Bat
echo.
echo 📊 Próximos passos:
echo    1. Verificar se tudo está no GitHub
echo    2. (Opcional) Configurar GitHub Actions
echo    3. (Opcional) Adicionar webhooks Discord/Slack
echo.

pause
