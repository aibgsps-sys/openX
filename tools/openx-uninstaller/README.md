# 🗑️ OpenX Uninstaller

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows-blue?style=for-the-badge" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Version-1.0-orange?style=for-the-badge" alt="Version">
</p>

**OpenX 系列产品一键卸载工具** - 免费开源，彻底清理 OpenX、OpenClaw、QClaw、360Claw 等所有换皮产品。

---

## 🇨🇳 中文说明

### ✨ 功能特性

- 🔍 **全盘扫描** - 搜索所有相关文件、文件夹、注册表
- 🗑️ **一键卸载** - 选择性删除扫描结果
- 📦 **多产品支持** - 支持 OpenX 系列所有换皮产品
- 🔐 **安全确认** - 多重警告防止误删
- 🎨 **图形界面** - 现代化深色主题 UI

### 📋 支持的产品

| 产品名 | 说明 |
|--------|------|
| OpenX | 默认产品 |
| OpenClaw | 换皮产品 |
| QClaw | 换皮产品 |
| 360Claw | 换皮产品 |
| Clawdbot | 原版名称 |
| Moltbot | 别名 |
| Pi-AI | 别名 |
| Clawd | 别名 |
| *自定义* | 支持手动输入任意名称 |

### 🔧 扫描范围

| 类型 | 说明 |
|------|------|
| 文件/文件夹 | 用户目录、AppData、Program Files 等 |
| NPM/PNPM 包 | 全局安装的包 |
| 环境变量 | PATH、HOME 等 |
| Windows 服务 | 系统服务 |
| 计划任务 | 任务计划程序 |
| 注册表 | 软件注册表、启动项、卸载信息 |

### 🚀 使用方法

```bash
# 方式一：双击运行
双击 uninstall.bat

# 方式二：PowerShell 运行
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

### ⚠️ 注意事项

1. **需要管理员权限** - 工具会自动请求管理员权限
2. **删除不可恢复** - 删除的文件不会进入回收站
3. **谨慎操作** - 请仔细检查扫描结果后再确认删除

---

## 🇺🇸 English

### ✨ Features

- 🔍 **Full Disk Scan** - Search all related files, folders, registry
- 🗑️ **One-Click Uninstall** - Selective deletion of scan results
- 📦 **Multi-Product Support** - Support all OpenX series products
- 🔐 **Safe Confirmation** - Multiple warnings to prevent accidental deletion
- 🎨 **GUI** - Modern dark theme UI

### 🚀 Usage

```bash
# Double-click uninstall.bat
# Or run in PowerShell:
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

### ⚠️ Warning

- **Requires Administrator Privileges**
- **Deleted files cannot be recovered**
- **Please check scan results carefully before confirming deletion**

---

## 📄 License

MIT License - Free to use, modify, and distribute.

Copyright (c) 2026 OpenX Team

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📞 Support

- GitHub Issues: [Report a bug](https://github.com/aibgsps-sys/openX/issues)
