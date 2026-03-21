@echo off
chcp 65001 >nul
title OpenX 一键启动

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 正在请求管理员权限...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ========================================
echo   OpenX 一键安装启动脚本
echo ========================================
echo.

:: 设置项目目录
set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

:: 检查 Node.js
echo [1/6] 检查 Node.js...
where node >nul 2>&1
if %errorLevel% neq 0 (
    echo Node.js 未安装，正在安装...
    echo.
    echo 请选择安装方式：
    echo 1. 自动下载安装 Node.js LTS (推荐)
    echo 2. 手动安装 (打开官网下载页)
    echo 3. 跳过 (已自行安装)
    echo.
    set /p node_choice="请输入选项 (1/2/3): "
    
    if "%node_choice%"=="1" (
        echo 正在下载 Node.js LTS...
        powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v22.14.0/node-v22.14.0-x64.msi' -OutFile '%TEMP%\nodejs.msi'"
        echo 正在安装 Node.js...
        msiexec /i "%TEMP%\nodejs.msi" /qn
        echo Node.js 安装完成！
        echo 请关闭此窗口，重新运行脚本。
        pause
        exit /b
    )
    if "%node_choice%"=="2" (
        start https://nodejs.org/
        echo 请安装 Node.js 后重新运行此脚本。
        pause
        exit /b
    )
)

:: 显示 Node.js 版本
for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
echo Node.js 版本: %NODE_VERSION%

:: 检查 pnpm
echo.
echo [2/6] 检查 pnpm...
where pnpm >nul 2>&1
if %errorLevel% neq 0 (
    echo pnpm 未安装，正在安装...
    npm install -g pnpm
    if %errorLevel% neq 0 (
        echo pnpm 安装失败，尝试使用 npm...
        set "PKG_MANAGER=npm"
    ) else (
        set "PKG_MANAGER=pnpm"
    )
) else (
    set "PKG_MANAGER=pnpm"
)
for /f "tokens=*" %%i in ('pnpm -v 2^>nul') do set PNPM_VERSION=%%i
echo pnpm 版本: %PNPM_VERSION%

:: 安装依赖
echo.
echo [3/6] 安装项目依赖...
if "%PKG_MANAGER%"=="pnpm" (
    pnpm install
) else (
    npm install
)

:: 构建 UI
echo.
echo [4/6] 构建 UI...
if "%PKG_MANAGER%"=="pnpm" (
    pnpm ui:build
) else (
    npm run ui:build
)

:: 构建项目
echo.
echo [5/6] 构建项目...
if "%PKG_MANAGER%"=="pnpm" (
    pnpm build
) else (
    npm run build
)

:: 配置检查
echo.
echo [6/6] 检查配置...
if not exist "%USERPROFILE%\.clawdbot" mkdir "%USERPROFILE%\.clawdbot"
if not exist "%USERPROFILE%\.clawdbot\openx.json" (
    echo 创建默认配置文件...
    echo {"gateway":{"mode":"local","auth":{"mode":"token","token":"openx-default-token"}}} > "%USERPROFILE%\.clawdbot\openx.json"
)

echo.
echo ========================================
echo   安装完成！
echo ========================================
echo.
echo 正在启动 OpenX 网关...
echo.
echo 控制台地址: http://127.0.0.1:18789/ui/
echo.

:: 启动网关
node openx.mjs gateway --dev --allow-unconfigured

pause
