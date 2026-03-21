@echo off
chcp 65001 >nul
title OpenX 快速启动

echo.
echo ========================================
echo   OpenX 快速启动
echo ========================================
echo.

cd /d "%~dp0"

:: 检查是否已安装
if not exist "node_modules" (
    echo 检测到首次运行，正在执行完整安装...
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0start.ps1"
    exit /b
)

echo 正在启动 OpenX 网关...
echo.
echo 控制台地址: http://127.0.0.1:18789/ui/
echo.

node openx.mjs gateway --dev --allow-unconfigured

pause
