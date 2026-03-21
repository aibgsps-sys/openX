#Requires -RunAsAdministrator
# OpenX 系列产品一键卸载工具
# 支持 OpenX、OpenClaw、QClaw、360Claw 等所有换皮产品

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Host.UI.RawUI.WindowTitle = "OpenX 系列产品卸载工具"

$Global:ScanResults = @()
$Global:SelectedProduct = "openx"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    if ($Level -eq "ERROR") {
        Write-Host $logMessage -ForegroundColor Red
    } elseif ($Level -eq "WARN") {
        Write-Host $logMessage -ForegroundColor Yellow
    } elseif ($Level -eq "SUCCESS") {
        Write-Host $logMessage -ForegroundColor Green
    } else {
        Write-Host $logMessage -ForegroundColor Cyan
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
    $searchPatterns = @(
        $ProductName,
        "$ProductName*",
        "*$ProductName*",
        ".clawdbot",
        ".clawd",
        "clawdbot",
        "clawd"
    )
    
    $searchLocations = @(
        $env:USERPROFILE,
        $env:LOCALAPPDATA,
        $env:APPDATA,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        $env:TEMP,
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents",
        "$env:USERPROFILE\Downloads"
    )
    
    Write-Log "正在扫描 $ProductName 相关文件..."
    
    foreach ($location in $searchLocations) {
        if (Test-Path $location) {
            foreach ($pattern in $searchPatterns) {
                try {
                    $items = Get-ChildItem -Path $location -Filter $pattern -Recurse -ErrorAction SilentlyContinue -Depth 3
                    foreach ($item in $items) {
                        $results += [PSCustomObject]@{
                            Type = "File/Folder"
                            Path = $item.FullName
                            Size = if ($item.PSIsContainer) { (Get-ChildItem $item.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum } else { $item.Length }
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
                $results += [PSCustomObject]@{
                    Type = "NPM Global Package"
                    Path = $pkg.FullName
                    Size = (Get-ChildItem $pkg.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    Product = $ProductName
                }
            }
        }
    } catch {}
    
    try {
        $pnpmRoot = pnpm root -g 2>$null
        if ($pnpmRoot -and (Test-Path $pnpmRoot)) {
            $packages = Get-ChildItem $pnpmRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$ProductName*" }
            foreach ($pkg in $packages) {
                $results += [PSCustomObject]@{
                    Type = "PNPM Global Package"
                    Path = $pkg.FullName
                    Size = (Get-ChildItem $pkg.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                    Product = $ProductName
                }
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
            $results += [PSCustomObject]@{
                Type = "User Environment Variable"
                Path = "$varName = $userValue"
                Size = 0
                Product = $ProductName
            }
        }
        
        if ($machineValue -and $machineValue -like "*$ProductName*") {
            $results += [PSCustomObject]@{
                Type = "System Environment Variable"
                Path = "$varName = $machineValue"
                Size = 0
                Product = $ProductName
            }
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
            $results += [PSCustomObject]@{
                Type = "Windows Service"
                Path = "$($svc.Name) ($($svc.DisplayName))"
                Size = 0
                Product = $ProductName
            }
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
            $results += [PSCustomObject]@{
                Type = "Scheduled Task"
                Path = "$($task.TaskPath)$($task.TaskName)"
                Size = 0
                Product = $ProductName
            }
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
                        Type = "Registry Key"
                        Path = $displayPath
                        Size = 0
                        Product = $ProductName
                        RegistryKey = $item.PSPath
                    }
                }
                
                $properties = Get-Item -Path $regPath -ErrorAction SilentlyContinue | Where-Object {
                    $_.GetValueNames() | ForEach-Object {
                        $val = $_.GetValue($_)
                        $val -like "*$ProductName*"
                    }
                }
                
                foreach ($prop in $properties) {
                    $displayPath = $prop.PSPath -replace "Microsoft\.PowerShell\.Core\\Registry::", ""
                    if ($results.Path -notcontains $displayPath) {
                        $results += [PSCustomObject]@{
                            Type = "Registry Key"
                            Path = $displayPath
                            Size = 0
                            Product = $ProductName
                            RegistryKey = $prop.PSPath
                        }
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
        $StatusLabel.Text = "正在删除: $($item.Path)"
        [System.Windows.Forms.Application]::DoEvents()
        
        try {
            switch ($item.Type) {
                { $_ -in @("File/Folder", "NPM Global Package", "PNPM Global Package") } {
                    if (Test-Path $item.Path) {
                        Remove-Item $item.Path -Recurse -Force -ErrorAction Stop
                        Write-Log "已删除: $($item.Path)" "SUCCESS"
                    }
                }
                "User Environment Variable" {
                    $parts = $item.Path -split " = ", 2
                    $varName = $parts[0]
                    $varValue = $parts[1]
                    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                    if ($currentPath) {
                        $newPath = ($currentPath -split ";" | Where-Object { $_ -notlike "*$Global:SelectedProduct*" }) -join ";"
                        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
                        Write-Log "已清理用户环境变量: $varName" "SUCCESS"
                    }
                }
                "System Environment Variable" {
                    $parts = $item.Path -split " = ", 2
                    $varName = $parts[0]
                    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                    if ($currentPath) {
                        $newPath = ($currentPath -split ";" | Where-Object { $_ -notlike "*$Global:SelectedProduct*" }) -join ";"
                        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
                        Write-Log "已清理系统环境变量: $varName" "SUCCESS"
                    }
                }
                "Windows Service" {
                    $svcName = $item.Path -split " \(" | Select-Object -First 1
                    Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                    sc.exe delete $svcName 2>$null
                    Write-Log "已删除服务: $svcName" "SUCCESS"
                }
                "Scheduled Task" {
                    Unregister-ScheduledTask -TaskName $item.Path -Confirm:$false -ErrorAction SilentlyContinue
                    Write-Log "已删除计划任务: $($item.Path)" "SUCCESS"
                }
                "Registry Key" {
                    if ($item.RegistryKey) {
                        Remove-Item -Path $item.RegistryKey -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Log "已删除注册表: $($item.Path)" "SUCCESS"
                    }
                }
            }
        } catch {
            Write-Log "删除失败: $($item.Path) - $_" "ERROR"
        }
    }
}

function Show-MainForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "OpenX 系列产品卸载工具 v1.0"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $form.ForeColor = [System.Drawing.Color]::White

    $titleFont = New-Object System.Drawing.Font("Microsoft YaHei", 16, [System.Drawing.FontStyle]::Bold)
    $normalFont = New-Object System.Drawing.Font("Microsoft YaHei", 10)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "🗑️ OpenX 系列产品卸载工具"
    $titleLabel.Font = $titleFont
    $titleLabel.Size = New-Object System.Drawing.Size(760, 40)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($titleLabel)

    $productLabel = New-Object System.Windows.Forms.Label
    $productLabel.Text = "选择要卸载的产品："
    $productLabel.Font = $normalFont
    $productLabel.Size = New-Object System.Drawing.Size(150, 30)
    $productLabel.Location = New-Object System.Drawing.Point(20, 80)
    $form.Controls.Add($productLabel)

    $productCombo = New-Object System.Windows.Forms.ComboBox
    $productCombo.Font = $normalFont
    $productCombo.Size = New-Object System.Drawing.Size(300, 30)
    $productCombo.Location = New-Object System.Drawing.Point(170, 77)
    $productCombo.DropDownStyle = "DropDown"
    $productCombo.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $productCombo.ForeColor = [System.Drawing.Color]::White
    
    $products = Get-KnownProducts
    foreach ($p in $products) {
        $productCombo.Items.Add($p.DisplayName) | Out-Null
    }
    $productCombo.SelectedIndex = 0
    $form.Controls.Add($productCombo)

    $orLabel = New-Object System.Windows.Forms.Label
    $orLabel.Text = "或手动输入："
    $orLabel.Font = $normalFont
    $orLabel.Size = New-Object System.Drawing.Size(80, 30)
    $orLabel.Location = New-Object System.Drawing.Point(490, 80)
    $form.Controls.Add($orLabel)

    $customProductText = New-Object System.Windows.Forms.TextBox
    $customProductText.Font = $normalFont
    $customProductText.Size = New-Object System.Drawing.Size(200, 30)
    $customProductText.Location = New-Object System.Drawing.Point(570, 77)
    $customProductText.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $customProductText.ForeColor = [System.Drawing.Color]::White
    $customProductText.BorderStyle = "FixedSingle"
    $form.Controls.Add($customProductText)

    $scanButton = New-Object System.Windows.Forms.Button
    $scanButton.Text = "🔍 全盘扫描"
    $scanButton.Font = $normalFont
    $scanButton.Size = New-Object System.Drawing.Size(150, 40)
    $scanButton.Location = New-Object System.Drawing.Point(20, 130)
    $scanButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $scanButton.ForeColor = [System.Drawing.Color]::White
    $scanButton.FlatStyle = "Flat"
    $form.Controls.Add($scanButton)

    $uninstallButton = New-Object System.Windows.Forms.Button
    $uninstallButton.Text = "🗑️ 一键卸载"
    $uninstallButton.Font = $normalFont
    $uninstallButton.Size = New-Object System.Drawing.Size(150, 40)
    $uninstallButton.Location = New-Object System.Drawing.Point(180, 130)
    $uninstallButton.BackColor = [System.Drawing.Color]::FromArgb(192, 0, 0)
    $uninstallButton.ForeColor = [System.Drawing.Color]::White
    $uninstallButton.FlatStyle = "Flat"
    $uninstallButton.Enabled = $false
    $form.Controls.Add($uninstallButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "❌ 取消"
    $cancelButton.Font = $normalFont
    $cancelButton.Size = New-Object System.Drawing.Size(150, 40)
    $cancelButton.Location = New-Object System.Drawing.Point(340, 130)
    $cancelButton.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $cancelButton.ForeColor = [System.Drawing.Color]::White
    $cancelButton.FlatStyle = "Flat"
    $form.Controls.Add($cancelButton)

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Size = New-Object System.Drawing.Size(740, 25)
    $progressBar.Location = New-Object System.Drawing.Point(20, 185)
    $progressBar.Style = "Continuous"
    $form.Controls.Add($progressBar)

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = "就绪"
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
    $resultListView.Columns.Add("类型", 150) | Out-Null
    $resultListView.Columns.Add("路径", 450) | Out-Null
    $resultListView.Columns.Add("大小", 100) | Out-Null
    
    $checkBoxes = New-Object System.Windows.Forms.CheckBox
    $resultListView.CheckBoxes = $true
    $form.Controls.Add($resultListView)

    $totalSizeLabel = New-Object System.Windows.Forms.Label
    $totalSizeLabel.Text = "总大小: 0 MB"
    $totalSizeLabel.Font = $normalFont
    $totalSizeLabel.Size = New-Object System.Drawing.Size(300, 25)
    $totalSizeLabel.Location = New-Object System.Drawing.Point(20, 535)
    $form.Controls.Add($totalSizeLabel)

    $scanButton.Add_Click({
        $productName = if ($customProductText.Text) { $customProductText.Text.ToLower() } else { 
            $selected = $productCombo.SelectedItem
            ($products | Where-Object { $_.DisplayName -eq $selected }).Name
        }
        $Global:SelectedProduct = $productName
        
        $statusLabel.Text = "正在扫描 $productName..."
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
        
        $totalSizeLabel.Text = "总大小: $([math]::Round($totalSize / 1MB, 2)) MB | 共 $($Global:ScanResults.Count) 项"
        $statusLabel.Text = "扫描完成，找到 $($Global:ScanResults.Count) 项"
        $progressBar.Value = 100
        $uninstallButton.Enabled = $Global:ScanResults.Count -gt 0
    })

    $uninstallButton.Add_Click({
        $result = [System.Windows.Forms.MessageBox]::Show(
            "确定要卸载选中的项目吗？`n此操作不可恢复！",
            "确认卸载",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            $selectedItems = @()
            foreach ($listItem in $resultListView.Items) {
                if ($listItem.Checked) {
                    $selectedItems += $Global:ScanResults[$listItem.Index]
                }
            }
            
            if ($selectedItems.Count -gt 0) {
                Remove-ScannedItems -Items $selectedItems -ProgressBar $progressBar -StatusLabel $statusLabel
                [System.Windows.Forms.MessageBox]::Show(
                    "卸载完成！`n已删除 $($selectedItems.Count) 项",
                    "完成",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                $statusLabel.Text = "卸载完成"
                $resultListView.Items.Clear()
                $uninstallButton.Enabled = $false
            }
        }
    })

    $cancelButton.Add_Click({
        $form.Close()
    })

    $form.ShowDialog()
}

Show-MainForm
