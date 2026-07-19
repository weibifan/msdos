<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# MS-DOS 经典收藏集 🖥️

> 保存个人计算的基础——MS-DOS 环境、工具、启动盘和历史资源。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-MS--DOS%206.22-lightgrey)]()
[![Maintenance](https://img.shields.io/badge/maintained%3F-yes-green.svg)]()

---

## 📋 概述

本仓库是一个精心整理的 **MS-DOS 资源合集**，包括：

- **MS-DOS 6.22** — Ghost 磁盘镜像和启动盘
- **MS-DOS 7.10** — 最终版 DOS（来自 Windows 98 SE）
- **启动盘镜像** — DOS 救援盘、Windows 9x 启动盘及实用工具
- **虚拟机镜像** — 预配置的 [QEMU](ms-dos-in-qemu/README.md) 和 [VMware](ms-dos-in-vmware/README.md) 虚拟机
- **MS-DOS 6.0 源代码** — 供历史和教育参考
- **经典 Windows** — Windows 1.0 和中文 PWIN 3.2 安装盘

---

## 📦 仓库结构

```
msdos/
├── README.md                              # 本文件（英文版）
├── ms-dos-622.gho                         # MS-DOS 6.22 Ghost 系统镜像
├── Ghost60.exe                            # Norton Ghost 6.0（磁盘克隆工具）
│
├── boot-disk/                             # 启动盘镜像合集
│   ├── README.md                          #   说明文档
│   ├── ms-dos-622.img                     #   MS-DOS 6.22 启动盘
│   ├── ms-dos-boot.img                    #   通用 DOS 启动盘
│   ├── ms-dos-rescue.img                  #   DOS 救援盘
│   ├── rescue.img                         #   含恢复工具的实用盘
│   ├── unix.img                           #   UNIX 启动盘
│   ├── win95.img                          #   Windows 95 启动盘
│   ├── win97.img                          #   Windows 97（OEM）启动盘
│   ├── win98.img                          #   Windows 98 启动盘
│   ├── win98se.img                        #   Windows 98 SE 启动盘
│   ├── hd-copy.exe                        #   HD-COPY v2.3R — 软盘复制/映像工具
│   ├── undisk.exe                         #   磁盘镜像提取工具
│   └── undiskp.exe                        #   UNDISK（保护模式）
│
├── tools/                                 # DOS 实用工具
│   ├── pct9.zip                           #   PC Tools 9.0 工具套件
│   ├── sea13.zip                          #   Sea v1.3 图像查看器
│   └── README.md                          #   说明文档
│
├── ms-dos-7.10/                           # MS-DOS 7.1（最终版 DOS）
│   ├── ms-dos-71-disk1.zip                #   安装盘 1
│   ├── ms-dos-71-disk2.zip                #   安装盘 2
│   └── ms-dos-71-boot.zip                 #   启动盘
│
├── ms-dos-in-qemu/                        # QEMU 1.2 中的 MS-DOS 6.22
│   ├── README.md                          #   安装指南
│   ├── myimage.zip                        #   预构建的 QEMU 磁盘镜像
│   └── qemu-screenshot.png                #   截图
│
├── ms-dos-in-vmware/                      # VMware 5.5 中的 MS-DOS 6.22
│   ├── README.md                          #   安装指南
│   └── ms-dos-vmware-5.5.zip              #   预构建的 VMware 虚拟机
│
├── ms-dos-6.0-source-code.zip             # MS-DOS 6.0 源代码（教育用途）
├── chinese-windows-3.2-setup-disk.zip     # PWIN 3.2（中文 Windows 3.2）
├── windows-1.0-setup-disk.zip             # Windows 1.0 安装盘
├── UCDOS-7.0-WPS-CCED-6.0-setup.iso      # UCDOS 7.0（含 WPS）+ CCED 6.0
│
├── Turbo C 2.01 (5.25-360k)/              # Turbo C 2.01 开发环境
│   ├── Disk1 - Install - Help.img         #   安装与帮助（360KB）
│   ├── Disk2 - Integrated Development Environment.img  #   集成开发环境
│   ├── Disk3 - Command Line - Utilities.img #   命令行工具
│   ├── Disk4 - Libraries.img              #   库文件
│   ├── Disk5 - Header Files - Libraries.img #   头文件
│   └── Disk6 - Examples - BGI - Misc.img  #   示例与图形
│
└── Turbo C++ 3.0/                         # Turbo C++ 3.0 开发环境
    └── Turbo C++ 3.0.zip                  #   完整包
```

---

## 🚀 快速开始

### 方式一：QEMU（轻量级）

```bash
cd ms-dos-in-qemu
unzip myimage.zip
qemu-system-x86_64 -m 64 -drive file=myimage.img,format=raw
```

详见 [QEMU 指南](ms-dos-in-qemu/README.md)。

### 方式二：VMware Workstation

1. 解压 `ms-dos-in-vmware/ms-dos-vmware-5.5.zip`
2. 用 **VMware Workstation 5.x** 或更高版本打开 `.vmx` 文件
3. 开机运行

### 方式三：物理机 / 真实硬件

使用启动盘镜像配合软驱：

```bash
hd-copy.exe boot-disk/ms-dos-622.img
```

或使用 Norton Ghost 部署 Ghost 镜像 `ms-dos-622.gho`。

---

## 📚 内容详细介绍

### MS-DOS 6.22（1994）

最后一个独立零售版 MS-DOS。提供以下格式：
- **Ghost 镜像**（`ms-dos-622.gho`）— 可直接部署的系统镜像
- **启动盘**（`boot-disk/ms-dos-622.img`）— 1.44 MB 软盘镜像

### MS-DOS 7.10（1998）

最终版 DOS，随 Windows 98 SE 发布。引入了 FAT32 和大磁盘支持。包含三张软盘镜像用于安装。

### 虚拟机镜像

| 平台 | 镜像位置 | 说明 |
|----------|-----------|-------|
| **QEMU 1.2** | `ms-dos-in-qemu/` | 轻量级模拟，64 MB 内存，200 MB 磁盘 |
| **VMware 5.5** | `ms-dos-in-vmware/` | 预配置虚拟机，支持 VGA、软驱 |

### 经典 Windows 与中文 DOS 软件

| 文件 | 说明 |
|------|-------------|
| `windows-1.0-setup-disk.zip` | Microsoft Windows 1.0（1985）— 首个 GUI 操作系统 |
| `chinese-windows-3.2-setup-disk.zip` | PWIN 3.2 — 中文版 Windows 3.2 |
| `UCDOS-7.0-WPS-CCED-6.0-setup.iso` | **UCDOS 7.0**（含 WPS 文字处理）+ **CCED 6.0**（中文字表编辑）— 90 年代必备的中文 DOS 软件 |

### Turbo C / C++ 开发工具

| 目录 | 说明 |
|-----------|-------------|
| `Turbo C 2.01 (5.25-360k)/` | Turbo C 2.01 的 6 张磁盘镜像（每张 360KB）— Borland 出品的经典 MS-DOS C 语言编译器 |
| `Turbo C++ 3.0/` | 完整的 Turbo C++ 3.0 包 — Borland 面向对象的 DOS C++ IDE |

### 原始源代码

`ms-dos-6.0-source-code.zip` 包含 MS-DOS 6.0 的汇编源代码，由微软发布，供教育和历史参考。

---

## 🛠 启动盘工具

| 工具 | 说明 |
|------|-------------|
| **Ghost60.exe** | Norton Ghost 6.0 — 系统磁盘镜像与克隆 |
| **hd-copy.exe** | HD-COPY v2.3R — 快速软盘复制/映像工具（Oliver Fromme, Cardware） |
| **undisk.exe** | 提取/捕获磁盘镜像文件 |
| **undiskp.exe** | UNDISK 保护模式版本 |

---

## 🖥️ 经典 1996 年 PC 配置

一台 90 年代中期的高端 PC 配置，能够运行 MS-DOS 6.22、Windows 3.2 和早期的 Windows 9x：

| 组件 | 规格 |
|-----------|---------------|
| **CPU** | Intel 80486 DX2 — 66 MHz |
| **内存** | 8 MB |
| **存储** | 512 MB 硬盘 |
| **显卡** | S3 Graphics Adapter，1 MB 显存（Windows 3.2 下 640×480 高彩色） |
| **软驱** | 3.5 英寸软驱 × 1 |
| **光驱** | 2× 或 4× CD-ROM |
| **声卡** | Sound Blaster 16 |
| **鼠标** | Microsoft 兼容串口鼠标 |
| **网卡** | NE2000 兼容（后期加装） |

---

## ⚠️ 系统要求（MS-DOS 6.22）

| 组件 | 最低要求 | 推荐配置 |
|-----------|---------|-------------|
| CPU | 8088 | 486 DX 或更高 |
| 内存 | 640 KB | 4–16 MB |
| 存储 | 10 MB | 200 MB |
| 软驱 | 1.44 MB 软驱 | — |
| 显卡 | CGA | VGA |
| 启动介质 | 软盘或硬盘 | 装有 DOS 的硬盘 |

---

## 📖 参考链接

- [MS-DOS 历史](https://en.wikipedia.org/wiki/MS-DOS)
- [MS-DOS 6.22 技术参考](https://archive.org/details/msdos622)
- [DOS资源站 CN-DOS.net](https://www.cn-dos.net/) — 中文 DOS 社区与资源存档
- [老操作系统集锦](http://www.regexlab.com/sswater/zh/oldos.htm) — 复古操作系统收藏
- [QEMU 文档](https://www.qemu.org/documentation/)
- [FreeDOS](https://www.freedos.org/) — 现代免费 DOS 替代品

---

## 🤝 贡献指南

欢迎贡献！如果您有其他 MS-DOS 资源、工具或文档：

1. Fork 本仓库
2. 创建功能分支
3. 提交 Pull Request

> **注意**：原始 MS-DOS 组件归各自所有者所有。本合集仅供 **教育和存档用途**。

---

<p align="center">
  <sub>保存计算历史，一个字节接一个字节。🖥️</sub>
</p>
