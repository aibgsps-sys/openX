<#
.SYNOPSIS
    OpenX Uninstaller - OpenX Series Product Uninstall Tool
.DESCRIPTION
    A GUI tool to uninstall OpenX and related products completely.
.NOTES
    Copyright (c) 2026 OpenX Team
    Licensed under MIT License
#>

#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "OpenX Uninstaller"

$Global:ScanResults = @()
$Global:SelectedProduct = "openx"
$Global:CurrentLang = "en"

$Global:Lang = @{
    en = @{
        Title = "OpenX Uninstaller"
        SelectProduct = "Select Product:"
        OrEnter = "Or enter:"
        Scan = "Scan"
        Uninstall = "Uninstall"
        Cancel = "Cancel"
        Language = "Language:"
        Ready = "Ready"
        Total = "Total: {0} MB | {1} items"
        Type = "Type"
        Path = "Path"
        Size = "Size"
        Scanning = "Scanning {0}..."
        ScanComplete = "Scan complete: {0} items found"
        Deleting = "Deleting: {0}"
        UninstallComplete = "Uninstall complete"
        ScanConfirmTitle = "Scan Confirmation"
        ScanConfirmMsg = "Full disk scan for '{0}'?`n`nWill search:`n- Files and Folders`n- NPM/PNPM Packages`n- Environment Variables`n- Windows Services`n- Scheduled Tasks`n- Registry`n`nContinue?"
        SelectItemsTitle = "Info"
        SelectItemsMsg = "Please select items to delete!"
        WarningTitle = "Dangerous Operation"
        WarningMsg = "WARNING: About to delete {0} items!`n`n- Cannot be undone!`n- Data will be permanently lost!`n- Not recoverable from Recycle Bin!`n`nContinue?"
        FinalConfirmTitle = "Final Confirmation"
        FinalConfirmMsg = "FINAL CONFIRMATION`n`nAre you really sure?`nThis cannot be undone!"
        DoneTitle = "Done"
        DoneMsg = "Uninstall complete!`n`nDeleted {0} items"
        LogScanning = "Scanning files for {0}..."
        LogDeleted = "Deleted: {0}"
        LogCleanedUserEnv = "Cleaned user environment variable"
        LogCleanedSystemEnv = "Cleaned system environment variable"
        LogDeletedService = "Deleted service: {0}"
        LogDeletedTask = "Deleted task: {0}"
        LogDeletedRegistry = "Deleted registry: {0}"
        LogFailed = "Failed: {0} - {1}"
    }
    zh = @{
        Title = "OpenX 卸载工具"
        SelectProduct = "选择产品："
        OrEnter = "或输入："
        Scan = "扫描"
        Uninstall = "卸载"
        Cancel = "取消"
        Language = "语言："
        Ready = "就绪"
        Total = "总计: {0} MB | {1} 项"
        Type = "类型"
        Path = "路径"
        Size = "大小"
        Scanning = "正在扫描 {0}..."
        ScanComplete = "扫描完成: 找到 {0} 项"
        Deleting = "正在删除: {0}"
        UninstallComplete = "卸载完成"
        ScanConfirmTitle = "扫描确认"
        ScanConfirmMsg = "对 '{0}' 进行全盘扫描?`n`n将搜索:`n- 文件和文件夹`n- NPM/PNPM 包`n- 环境变量`n- Windows 服务`n- 计划任务`n- 注册表`n`n是否继续?"
        SelectItemsTitle = "提示"
        SelectItemsMsg = "请先勾选要删除的项目!"
        WarningTitle = "危险操作"
        WarningMsg = "警告: 即将删除 {0} 个项目!`n`n- 无法撤销!`n- 数据将永久丢失!`n- 回收站无法恢复!`n`n是否继续?"
        FinalConfirmTitle = "最终确认"
        FinalConfirmMsg = "最终确认`n`n您真的确定吗?`n此操作不可撤销!"
        DoneTitle = "完成"
        DoneMsg = "卸载完成!`n`n已删除 {0} 项"
        LogScanning = "正在扫描 {0} 相关文件..."
        LogDeleted = "已删除: {0}"
        LogCleanedUserEnv = "已清理用户环境变量"
        LogCleanedSystemEnv = "已清理系统环境变量"
        LogDeletedService = "已删除服务: {0}"
        LogDeletedTask = "已删除计划任务: {0}"
        LogDeletedRegistry = "已删除注册表: {0}"
        LogFailed = "删除失败: {0} - {1}"
    }
}

function Get-Text {
    param([string]$Key, [object[]]$FormatArgs = @())
    $text = $Global:Lang[$Global:CurrentLang][$Key]
    if ($FormatArgs.Count -gt 0) {
        return $text -f $FormatArgs
    }
    return $text
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    switch ($Level) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARN"    { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage -ForegroundColor Cyan }
    }
}

function Get-KnownProducts {
    return @(
        @{ Name = "openx"; DisplayName = "OpenX" },
        @{ Name = "openclaw"; DisplayName = "OpenClaw" },
        @{ Name = "qclaw"; DisplayName = "QClaw" },
        @{ Name = "360claw"; DisplayName = "360Claw" },
        @{ Name = "clawdbot"; DisplayName = "Clawdbot" },
        @{ Name = "moltbot"; DisplayName = "Moltbot" },
        @{ Name = "pi-ai"; DisplayName = "Pi-AI" },
        @{ Name = "clawd"; DisplayName = "Clawd" }
    )
}

function Search-ProductFiles {
    param([string]$ProductName)
    $results = @()
    $searchPatterns = @($ProductName, "$ProductName*", "*$ProductName*", ".clawdbot", ".clawd", "clawdbot", "clawd")
    $searchLocations = @($env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:TEMP)
    
    Write-Log (Get-Text "LogScanning" $ProductName)
    
    foreach ($location in $searchLocations) {
        if (Test-Path $location) {
            foreach ($pattern in $searchPatterns) {
                try {
                    $items = Get-ChildItem -Path $location -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Depth 3
                    foreach ($item in $items) {
                        $size = 0
                        if ($item.PSIsContainer) {
                            $size = (Get-ChildItem $item.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                        } else {
                            $size = $item.Length
                        }
                        $results += [PSCustomObject]@{
                            Type = "File/Folder"
                            Path = $item.FullName
                            Size = $size
                            Product = $ProductName
                        }
                    }
                } catch {}
            }
        }
    }
    return $results
}

function Search-NpmGlobalPackages {
    param([string]$ProductName)
    $results = @()
    try {
        $npmRoot = npm root -g 2>$null
        if ($npmRoot -and (Test-Path $npmRoot)) {
            $packages = Get-ChildItem $npmRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ProductName*" }
            foreach ($pkg in $packages) {
                $size = (Get-ChildItem $pkg.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $results += [PSCustomObject]@{ Type = "NPM Package"; Path = $pkg.FullName; Size = $size; Product = $ProductName }
            }
        }
    } catch {}
    return $results
}

function Search-PnpmGlobalPackages {
    param([string]$ProductName)
    $results = @()
    try {
        $pnpmRoot = pnpm root -g 2>$null
        if ($pnpmRoot -and (Test-Path $pnpmRoot)) {
            $packages = Get-ChildItem $pnpmRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ProductName*" }
            foreach ($pkg in $packages) {
                $size = (Get-ChildItem $pkg.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $results += [PSCustomObject]@{ Type = "PNPM Package"; Path = $pkg.FullName; Size = $size; Product = $ProductName }
            }
        }
        $pnpmStore = Join-Path $env:LOCALAPPDATA "pnpm-store"
        if (Test-Path $pnpmStore) {
            $storeItems = Get-ChildItem $pnpmStore -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ProductName*" }
            foreach ($item in $storeItems) {
                $size = (Get-ChildItem $item.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $results += [PSCustomObject]@{ Type = "PNPM Store"; Path = $item.FullName; Size = $size; Product = $ProductName }
            }
        }
    } catch {}
    return $results
}

function Search-EnvironmentVariables {
    param([string]$ProductName)
    $results = @()
    $varNames = @("PATH", "OPENX_HOME", "CLAWDBOT_HOME", "CLAWD_HOME")
    foreach ($varName in $varNames) {
        $userValue = [Environment]::GetEnvironmentVariable($varName, "User")
        $machineValue = [Environment]::GetEnvironmentVariable($varName, "Machine")
        if ($userValue -and $userValue -like "*$ProductName*") {
            $results += [PSCustomObject]@{ Type = "User Env"; Path = "$varName = $userValue"; Size = 0; Product = $ProductName }
        }
        if ($machineValue -and $machineValue -like "*$ProductName*") {
            $results += [PSCustomObject]@{ Type = "System Env"; Path = "$varName = $machineValue"; Size = 0; Product = $ProductName }
        }
    }
    return $results
}

function Search-Services {
    param([string]$ProductName)
    $results = @()
    try {
        $services = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ProductName*" -or $_.DisplayName -like "*$ProductName*" }
        foreach ($svc in $services) {
            $results += [PSCustomObject]@{ Type = "Service"; Path = "$($svc.Name) ($($svc.DisplayName))"; Size = 0; Product = $ProductName }
        }
    } catch {}
    return $results
}

function Search-ScheduledTasks {
    param([string]$ProductName)
    $results = @()
    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "*$ProductName*" -or $_.TaskPath -like "*$ProductName*" }
        foreach ($task in $tasks) {
            $results += [PSCustomObject]@{ Type = "Task"; Path = "$($task.TaskPath)$($task.TaskName)"; Size = 0; Product = $ProductName }
        }
    } catch {}
    return $results
}

function Search-Registry {
    param([string]$ProductName)
    $results = @()
    $registryPaths = @(
        "HKCU:\Software",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\WOW6432Node",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    foreach ($regPath in $registryPaths) {
        try {
            if (Test-Path $regPath) {
                $items = Get-ChildItem -Path $regPath -Recurse -ErrorAction SilentlyContinue | Where-Object {
                    $_.Name -like "*$ProductName*" -or 
                    ($_.GetValue("DisplayName") -like "*$ProductName*") -or
                    ($_.GetValue("Publisher") -like "*$ProductName*") -or
                    ($_.GetValue("InstallLocation") -like "*$ProductName*")
                }
                foreach ($item in $items) {
                    $displayPath = $item.PSPath -replace "Microsoft\.PowerShell\.Core\\Registry::", ""
                    $results += [PSCustomObject]@{ 
                        Type = "Registry"
                        Path = $displayPath
                        Size = 0
                        Product = $ProductName
                        RegistryKey = $item.PSPath
                    }
                }
            }
        } catch {}
    }
    return $results
}

function Start-FullScan {
    param([string]$ProductName)
    $Global:ScanResults = @()
    $Global:ScanResults += Search-ProductFiles -ProductName $ProductName
    $Global:ScanResults += Search-NpmGlobalPackages -ProductName $ProductName
    $Global:ScanResults += Search-PnpmGlobalPackages -ProductName $ProductName
    $Global:ScanResults += Search-EnvironmentVariables -ProductName $ProductName
    $Global:ScanResults += Search-Services -ProductName $ProductName
    $Global:ScanResults += Search-ScheduledTasks -ProductName $ProductName
    $Global:ScanResults += Search-Registry -ProductName $ProductName
    return $Global:ScanResults
}

function Remove-ScannedItems {
    param($Items, $ProgressBar, $StatusLabel)
    $total = $Items.Count
    $current = 0
    foreach ($item in $Items) {
        $current++
        $percent = [math]::Round(($current / $total) * 100)
        $ProgressBar.Value = $percent
        $StatusLabel.Text = Get-Text "Deleting" $item.Path
        [System.Windows.Forms.Application]::DoEvents()
        try {
            switch ($item.Type) {
                { $_ -in @("File/Folder", "NPM Package") } {
                    if (Test-Path $item.Path) {
                        Remove-Item $item.Path -Recurse -Force -ErrorAction Stop
                        Write-Log (Get-Text "LogDeleted" $item.Path) "SUCCESS"
                    }
                }
                "User Env" {
                    $varName = ($item.Path -split " = ")[0]
                    if ($varName -eq "PATH") {
                        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                        if ($currentPath) {
                            $newPath = ($currentPath -split ";" | Where-Object { 
                                $path = $_.Trim()
                                if ([string]::IsNullOrEmpty($path)) { return $true }
                                if ($path -like "*\$Global:SelectedProduct*" -or $path -like "*\\$Global:SelectedProduct*") { return $false }
                                if ($path -like "*$Global:SelectedProduct\*" -or $path -like "*$Global:SelectedProduct\\*") { return $false }
                                return $true
                            }) -join ";"
                            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                        }
                    } else {
                        [Environment]::SetEnvironmentVariable($varName, $null, "User")
                    }
                    Write-Log (Get-Text "LogCleanedUserEnv") "SUCCESS"
                }
                "System Env" {
                    $varName = ($item.Path -split " = ")[0]
                    if ($varName -eq "PATH") {
                        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                        if ($currentPath) {
                            $newPath = ($currentPath -split ";" | Where-Object { 
                                $path = $_.Trim()
                                if ([string]::IsNullOrEmpty($path)) { return $true }
                                if ($path -like "*\$Global:SelectedProduct*" -or $path -like "*\\$Global:SelectedProduct*") { return $false }
                                if ($path -like "*$Global:SelectedProduct\*" -or $path -like "*$Global:SelectedProduct\\*") { return $false }
                                return $true
                            }) -join ";"
                            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
                        }
                    } else {
                        [Environment]::SetEnvironmentVariable($varName, $null, "Machine")
                    }
                    Write-Log (Get-Text "LogCleanedSystemEnv") "SUCCESS"
                }
                "Service" {
                    $svcName = $item.Path -split " \(" | Select-Object -First 1
                    Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                    sc.exe delete $svcName 2>$null
                    Write-Log (Get-Text "LogDeletedService" $svcName) "SUCCESS"
                }
                "Task" {
                    Unregister-ScheduledTask -TaskName $item.Path -Confirm:$false -ErrorAction SilentlyContinue
                    Write-Log (Get-Text "LogDeletedTask" $item.Path) "SUCCESS"
                }
                "Registry" {
                    if ($item.RegistryKey) {
                        Remove-Item -Path $item.RegistryKey -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Log (Get-Text "LogDeletedRegistry" $item.Path) "SUCCESS"
                    }
                }
            }
        } catch {
            Write-Log (Get-Text "LogFailed" @($item.Path, $_)) "ERROR"
        }
    }
}

function Show-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "OpenX Uninstaller v1.0"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $form.ForeColor = [System.Drawing.Color]::White

    $titleFont = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $normalFont = New-Object System.Drawing.Font("Segoe UI", 10)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = Get-Text "Title"
    $titleLabel.Font = $titleFont
    $titleLabel.Size = New-Object System.Drawing.Size(600, 40)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.TextAlign = "MiddleLeft"
    $form.Controls.Add($titleLabel)

    $langLabel = New-Object System.Windows.Forms.Label
    $langLabel.Text = Get-Text "Language"
    $langLabel.Font = $normalFont
    $langLabel.Size = New-Object System.Drawing.Size(60, 30)
    $langLabel.Location = New-Object System.Drawing.Point(580, 20)
    $form.Controls.Add($langLabel)

    $langCombo = New-Object System.Windows.Forms.ComboBox
    $langCombo.Font = $normalFont
    $langCombo.Size = New-Object System.Drawing.Size(100, 30)
    $langCombo.Location = New-Object System.Drawing.Point(640, 17)
    $langCombo.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $langCombo.ForeColor = [System.Drawing.Color]::White
    $langCombo.FlatStyle = "Flat"
    $langCombo.Items.Add("English") | Out-Null
    $langCombo.Items.Add("Chinese") | Out-Null
    $langCombo.SelectedIndex = 0
    $form.Controls.Add($langCombo)

    $productLabel = New-Object System.Windows.Forms.Label
    $productLabel.Text = Get-Text "SelectProduct"
    $productLabel.Font = $normalFont
    $productLabel.Size = New-Object System.Drawing.Size(120, 30)
    $productLabel.Location = New-Object System.Drawing.Point(20, 80)
    $form.Controls.Add($productLabel)

    $productCombo = New-Object System.Windows.Forms.ComboBox
    $productCombo.Font = $normalFont
    $productCombo.Size = New-Object System.Drawing.Size(250, 30)
    $productCombo.Location = New-Object System.Drawing.Point(140, 77)
    $productCombo.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $productCombo.ForeColor = [System.Drawing.Color]::White
    $productCombo.FlatStyle = "Flat"
    $products = Get-KnownProducts
    foreach ($p in $products) { $productCombo.Items.Add($p.DisplayName) | Out-Null }
    $productCombo.SelectedIndex = 0
    $form.Controls.Add($productCombo)

    $orLabel = New-Object System.Windows.Forms.Label
    $orLabel.Text = Get-Text "OrEnter"
    $orLabel.Font = $normalFont
    $orLabel.Size = New-Object System.Drawing.Size(60, 30)
    $orLabel.Location = New-Object System.Drawing.Point(410, 80)
    $form.Controls.Add($orLabel)

    $customProductText = New-Object System.Windows.Forms.TextBox
    $customProductText.Font = $normalFont
    $customProductText.Size = New-Object System.Drawing.Size(180, 30)
    $customProductText.Location = New-Object System.Drawing.Point(470, 77)
    $customProductText.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $customProductText.ForeColor = [System.Drawing.Color]::White
    $customProductText.BorderStyle = "FixedSingle"
    $form.Controls.Add($customProductText)

    $scanButton = New-Object System.Windows.Forms.Button
    $scanButton.Text = Get-Text "Scan"
    $scanButton.Font = $normalFont
    $scanButton.Size = New-Object System.Drawing.Size(120, 40)
    $scanButton.Location = New-Object System.Drawing.Point(20, 130)
    $scanButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $scanButton.ForeColor = [System.Drawing.Color]::White
    $scanButton.FlatStyle = "Flat"
    $form.Controls.Add($scanButton)

    $uninstallButton = New-Object System.Windows.Forms.Button
    $uninstallButton.Text = Get-Text "Uninstall"
    $uninstallButton.Font = $normalFont
    $uninstallButton.Size = New-Object System.Drawing.Size(120, 40)
    $uninstallButton.Location = New-Object System.Drawing.Point(150, 130)
    $uninstallButton.BackColor = [System.Drawing.Color]::FromArgb(192, 0, 0)
    $uninstallButton.ForeColor = [System.Drawing.Color]::White
    $uninstallButton.FlatStyle = "Flat"
    $uninstallButton.Enabled = $false
    $form.Controls.Add($uninstallButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = Get-Text "Cancel"
    $cancelButton.Font = $normalFont
    $cancelButton.Size = New-Object System.Drawing.Size(120, 40)
    $cancelButton.Location = New-Object System.Drawing.Point(280, 130)
    $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.FlatStyle = "Flat"
    $form.Controls.Add($cancelButton)

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Size = New-Object System.Drawing.Size(740, 25)
    $progressBar.Location = New-Object System.Drawing.Point(20, 185)
    $form.Controls.Add($progressBar)

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = Get-Text "Ready"
    $statusLabel.Font = $normalFont
    $statusLabel.Size = New-Object System.Drawing.Size(740, 25)
    $statusLabel.Location = New-Object System.Drawing.Point(20, 215)
    $form.Controls.Add($statusLabel)

    $resultListView = New-Object System.Windows.Forms.ListView
    $resultListView.View = "Details"
    $resultListView.FullRowSelect = $true
    $resultListView.GridLines = $true
    $resultListView.Size = New-Object System.Drawing.Size(740, 280)
    $resultListView.Location = New-Object System.Drawing.Point(20, 250)
    $resultListView.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $resultListView.ForeColor = [System.Drawing.Color]::White
    $resultListView.Columns.Add((Get-Text "Type"), 120) | Out-Null
    $resultListView.Columns.Add((Get-Text "Path"), 500) | Out-Null
    $resultListView.Columns.Add((Get-Text "Size"), 80) | Out-Null
    $resultListView.CheckBoxes = $true
    $form.Controls.Add($resultListView)

    $totalSizeLabel = New-Object System.Windows.Forms.Label
    $totalSizeLabel.Text = Get-Text "Total" @(0, 0)
    $totalSizeLabel.Font = $normalFont
    $totalSizeLabel.Size = New-Object System.Drawing.Size(300, 25)
    $totalSizeLabel.Location = New-Object System.Drawing.Point(20, 535)
    $form.Controls.Add($totalSizeLabel)

    $updateLanguage = {
        $Global:CurrentLang = if ($langCombo.SelectedIndex -eq 1) { "zh" } else { "en" }
        $titleLabel.Text = Get-Text "Title"
        $langLabel.Text = Get-Text "Language"
        $productLabel.Text = Get-Text "SelectProduct"
        $orLabel.Text = Get-Text "OrEnter"
        $scanButton.Text = Get-Text "Scan"
        $uninstallButton.Text = Get-Text "Uninstall"
        $cancelButton.Text = Get-Text "Cancel"
        $statusLabel.Text = Get-Text "Ready"
        $resultListView.Columns[0].Text = Get-Text "Type"
        $resultListView.Columns[1].Text = Get-Text "Path"
        $resultListView.Columns[2].Text = Get-Text "Size"
    }

    $langCombo.Add_SelectedIndexChanged($updateLanguage)

    $scanButton.Add_Click({
        $productName = if ($customProductText.Text) { $customProductText.Text.ToLower() } else { 
            $selected = $productCombo.SelectedItem
            ($products | Where-Object { $_.DisplayName -eq $selected }).Name
        }
        $Global:SelectedProduct = $productName
        
        $scanWarning = [System.Windows.Forms.MessageBox]::Show(
            (Get-Text "ScanConfirmMsg" $productName),
            (Get-Text "ScanConfirmTitle"),
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($scanWarning -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        
        $statusLabel.Text = Get-Text "Scanning" $productName
        $progressBar.Value = 0
        $resultListView.Items.Clear()
        [System.Windows.Forms.Application]::DoEvents()
        
        Start-FullScan -ProductName $productName | Out-Null
        
        $totalSize = 0
        foreach ($item in $Global:ScanResults) {
            $listItem = New-Object System.Windows.Forms.ListViewItem($item.Type)
            $listItem.SubItems.Add($item.Path) | Out-Null
            $sizeMB = if ($item.Size) { [math]::Round($item.Size / 1MB, 2) } else { 0 }
            $listItem.SubItems.Add("$sizeMB MB") | Out-Null
            $listItem.Checked = $true
            $resultListView.Items.Add($listItem) | Out-Null
            $totalSize += $item.Size
        }
        
        $totalSizeLabel.Text = Get-Text "Total" @([math]::Round($totalSize / 1MB, 2), $Global:ScanResults.Count)
        $statusLabel.Text = Get-Text "ScanComplete" $Global:ScanResults.Count
        $progressBar.Value = 100
        $uninstallButton.Enabled = $Global:ScanResults.Count -gt 0
    })

    $uninstallButton.Add_Click({
        $selectedCount = ($resultListView.Items | Where-Object { $_.Checked }).Count
        if ($selectedCount -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                (Get-Text "SelectItemsMsg"),
                (Get-Text "SelectItemsTitle"),
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            return
        }
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            (Get-Text "WarningMsg" $selectedCount),
            (Get-Text "WarningTitle"),
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            $secondConfirm = [System.Windows.Forms.MessageBox]::Show(
                (Get-Text "FinalConfirmMsg"),
                (Get-Text "FinalConfirmTitle"),
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Exclamation
            )
            
            if ($secondConfirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }
            
            $selectedItems = @()
            foreach ($listItem in $resultListView.Items) {
                if ($listItem.Checked) {
                    $selectedItems += $Global:ScanResults[$listItem.Index]
                }
            }
            
            if ($selectedItems.Count -gt 0) {
                Remove-ScannedItems -Items $selectedItems -ProgressBar $progressBar -StatusLabel $statusLabel
                [System.Windows.Forms.MessageBox]::Show(
                    (Get-Text "DoneMsg" $selectedItems.Count),
                    (Get-Text "DoneTitle"),
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                $statusLabel.Text = Get-Text "UninstallComplete"
                $resultListView.Items.Clear()
                $uninstallButton.Enabled = $false
            }
        }
    })

    $cancelButton.Add_Click({ $form.Close() })
    $form.ShowDialog()
}

Show-MainForm
