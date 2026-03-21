@echo off
title OpenX Uninstaller

echo.
echo ========================================
echo   OpenX Uninstaller
echo ========================================
echo.
echo Starting uninstaller...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0tools\openx-uninstaller\uninstall.ps1"

pause
