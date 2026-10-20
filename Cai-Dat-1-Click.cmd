@echo off
chcp 65001 >nul
setlocal
title Cai Dat 1-Click - Claude Code Prompt Hub
cd /d "%~dp0"

echo ========================================================
echo    DANG TIEN HANH CAI DAT TU DONG 1-CLICK
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Cai-Dat-1-Click.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [LOI] Co loi xay ra trong qua trinh cai dat. Vui long kiem tra quyen PowerShell.
    pause
)
