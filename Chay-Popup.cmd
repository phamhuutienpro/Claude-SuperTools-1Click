@echo off
rem Sieu Cong Cu Claude Code
set "D=%~dp0"
if not exist "%D%popup-host.ps1" set "D=%USERPROFILE%\.claude\tools\"
start "" /min powershell -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "%D%popup-host.ps1"
exit /b 0
