#Requires -RunAsAdministrator
# OpenX 一键安装启动脚本
# 编码: UTF-8

$Host.UI.RawUI.WindowTitle = "OpenX 一键启动"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectDir

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
}

function Test-Command {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-NodeJS {
    Write-Host "Node.js 未检测到，请选择安装方式：" -ForegroundColor Yellow
    Write-Host "1. 自动安装 Node.js 22 LTS (推荐)"
    Write-Host "2. 使用 winget 安装 (Windows 10/11)"
    Write-Host "3. 打开官网手动下载"
    Write-Host "4. 跳过 (已自行安装)"
    
    $choice = Read-Host "请输入选项"
    
    switch ($choice) {
        "1" {
            Write-Host "正在下载 Node.js 22 LTS..."
            $nodeUrl = "https://nodejs.org/dist/v22.14.0/node-v22.14.0-x64.msi"
            $nodeMsi = "$env:TEMP\nodejs.msi"
            
            try {
                Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeMsi -UseBasicParsing
                Write-Host "正在安装 Node.js..."
                Start-Process msiexec.exe -ArgumentList "/i `"$nodeMsi`" /qn" -Wait
                Write-Host "Node.js 安装完成！" -ForegroundColor Green
                Write-Host "请关闭此窗口，重新运行脚本。" -ForegroundColor Yellow
                exit 0
            } catch {
                Write-Host "自动安装失败: $_" -ForegroundColor Red
                Write-Host "请手动安装 Node.js" -ForegroundColor Yellow
                Start-Process "https://nodejs.org/"
                exit 1
            }
        }
        "2" {
            if (Test-Command "winget") {
                Write-Host "正在使用 winget 安装 Node.js..."
                winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
                Write-Host "安装完成！请重新运行脚本。" -ForegroundColor Green
                exit 0
            } else {
                Write-Host "winget 不可用，请选择其他方式" -ForegroundColor Red
                exit 1
            }
        }
        "3" {
            Start-Process "https://nodejs.org/"
            Write-Host "请安装后重新运行此脚本" -ForegroundColor Yellow
            exit 0
        }
        "4" {
            Write-Host "已跳过 Node.js 安装"
        }
        default {
            Write-Host "无效选项，跳过安装" -ForegroundColor Red
        }
    }
}

function Install-Pnpm {
    if (-not (Test-Command "pnpm")) {
        Write-Host "正在安装 pnpm..." -ForegroundColor Yellow
        npm install -g pnpm
        if ($LASTEXITCODE -eq 0) {
            Write-Host "pnpm 安装成功！" -ForegroundColor Green
            return $true
        } else {
            Write-Host "pnpm 安装失败，将使用 npm" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

function New-DefaultConfig {
    $configDir = "$env:USERPROFILE\.clawdbot"
    $configFile = "$configDir\openx.json"
    
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    if (-not (Test-Path $configFile)) {
        Write-Host "创建默认配置文件..."
        $defaultConfig = @{
            gateway = @{
                mode = "local"
                auth = @{
                    mode = "token"
                    token = "openx-default-token"
                }
                port = 18789
            }
            agents = @{
                defaults = @{
                    workspace = "$env:USERPROFILE\openx-workspace"
                }
            }
        }
        $defaultConfig | ConvertTo-Json -Depth 10 | Out-File $configFile -Encoding UTF8
    }
}

# 主流程
Write-Host ""
Write-Host "  ██████╗ ██████╗ ███████╗███╗   ██╗" -ForegroundColor Red
Write-Host " ██╔═══██╗██╔══██╗██╔════╝████╗  ██║" -ForegroundColor Red
Write-Host " ██║   ██║██████╔╝█████╗  ██╔██╗ ██║" -ForegroundColor Red
Write-Host " ██║   ██║██╔══██╗██╔══╝  ██║╚██╗██║" -ForegroundColor Red
Write-Host " ╚██████╔╝██║  ██║███████╗██║ ╚████║" -ForegroundColor Red
Write-Host "  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝" -ForegroundColor Red
Write-Host ""

# 1. 检查 Node.js
Write-Step "步骤 1/6: 检查 Node.js"
if (Test-Command "node") {
    $nodeVersion = node -v
    Write-Host "Node.js 版本: $nodeVersion" -ForegroundColor Green
    
    # 检查版本是否 >= 18
    $versionNum = [int]($nodeVersion -replace 'v(\d+).*', '$1')
    if ($versionNum -lt 18) {
        Write-Host "警告: Node.js 版本过低，建议升级到 18+" -ForegroundColor Yellow
    }
} else {
    Install-NodeJS
    exit 0
}

# 2. 检查 pnpm
Write-Step "步骤 2/6: 检查 pnpm"
$usePnpm = Install-Pnpm
if ($usePnpm) {
    $pkgManager = "pnpm"
    $pnpmVersion = pnpm -v
    Write-Host "pnpm 版本: $pnpmVersion" -ForegroundColor Green
} else {
    $pkgManager = "npm"
    Write-Host "使用 npm 作为包管理器" -ForegroundColor Yellow
}

# 3. 安装依赖
Write-Step "步骤 3/6: 安装项目依赖"
Write-Host "这可能需要几分钟..." -ForegroundColor Gray
if ($usePnpm) {
    pnpm install
} else {
    npm install
}

# 4. 构建 UI
Write-Step "步骤 4/6: 构建 UI"
if ($usePnpm) {
    pnpm ui:build
} else {
    npm run ui:build
}

# 5. 构建项目
Write-Step "步骤 5/6: 构建项目"
if ($usePnpm) {
    pnpm build
} else {
    npm run build
}

# 6. 配置环境
Write-Step "步骤 6/6: 配置环境"
New-DefaultConfig

# 完成
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "控制台地址: " -NoNewline
Write-Host "http://127.0.0.1:18789/ui/" -ForegroundColor Cyan
Write-Host ""
Write-Host "正在启动 OpenX 网关..." -ForegroundColor Yellow
Write-Host ""

# 启动网关
node openx.mjs gateway --dev --allow-unconfigured
