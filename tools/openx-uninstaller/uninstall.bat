@echo off
title OpenX Uninstaller

echo.
echo ========================================
echo   OpenX Uninstaller
echo ========================================
echo.
echo Starting uninstaller...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"

pause
