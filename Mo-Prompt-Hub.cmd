@echo off
setlocal
cd /d "%~dp0"
if exist "%~dp0tools\prompt-hub.html" (
    start "" "%~dp0tools\prompt-hub.html"
) else (
    start "" "%USERPROFILE%\.claude\tools\prompt-hub.html"
)
exit /b 0
