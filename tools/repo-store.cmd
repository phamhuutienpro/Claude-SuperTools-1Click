@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0repo-store.ps1" %*
