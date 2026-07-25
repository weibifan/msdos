# BIOS / UEFI 裸机游戏

本目录探索**在无操作系统环境下**直接利用 UEFI 固件的 **GOP（Graphics Output Protocol）** 运行经典游戏。

## 游戏

| 游戏 | 启动方式 | 状态 |
|------|----------|------|
| **超级马力欧兄弟** | `start-mario.bat` | ✅ 已预编译 (`super-mario/smb.efi`) |
| **魂斗罗** | `start-contra.bat` | ⏳ 仅源码 — 见 `contra/build.bat` 编译 |

## 目录结构

| 路径 | 说明 |
|------|------|
| `OVMF/` | OVMF 固件文件（QEMU 的 UEFI 固件实现） |
| `super-mario/` | 超级马力欧兄弟 UEFI 移植 — 含 `smb.efi` + `startup.nsh` |
| `contra/` | [UEFI_Contra](https://github.com/MikeWuPing/UEFI_Contra) 源码 + 编译指南 |
| `contra/contra-uefi/` | NES 魂斗罗 UEFI Shell 移植（C 源码） |
| `contra/build.bat` | Contra.efi 编译指南（需 VS2019 + EDK2） |
| `start-mario.bat` | 启动超级马力欧兄弟 |
| `start-contra.bat` | 启动魂斗罗（需先编译）|
| `docs/` | 深入技术文章（UEFI、GOP、NES、魂斗罗分析）|

## 快速开始

### 前置条件

- [QEMU](https://www.qemu.org/) （已安装于 `C:\Program Files\qemu`）

### 运行超级马力欧兄弟

```batch
start-mario.bat
```

### 编译并运行魂斗罗

见 `contra/build.bat` 完整 EDK2 编译说明（需 VS2019 + EDK2 + NASM）。

## 文档

| 文件 | 说明 |
|------|------|
| `docs/uefi-overview.zh-CN.md` | UEFI 架构、启动流程、协议概述 |
| `docs/bios-legacy.zh-CN.md` | 传统 BIOS 加电→POST→MBR→OS 全流程 |
| `docs/gop-protocol.zh-CN.md` | 图形输出协议（GOP）— 帧缓冲、Blt、模式设置 |
| `docs/nes-architecture.zh-CN.md` | NES 硬件架构：PPU、2BPP 瓦片、调色板、Super-Tile |
| `docs/contra-uefi-analysis.zh-CN.md` | UEFI_Contra 源码级分析：渲染管线、状态机、碰撞检测 |

## 参考资料

- [UEFI_Contra](https://github.com/MikeWuPing/UEFI_Contra) — MikeWuPing 的原始项目
- [NESDev Wiki](https://www.nesdev.org/wiki/) — NES 硬件参考
- [OSDev Wiki - GOP](https://wiki.osdev.org/GOP) — 图形输出协议
- [UEFI 规范](https://uefi.org/specs/UEFI/2.11/) — 官方规范
- [OVMF 项目](https://github.com/tianocore/tianocore.github.io/wiki/OVMF) — 开放虚拟机固件
