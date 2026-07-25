# UEFI Overview

## 什么是 UEFI？

UEFI（统一可扩展固件接口）是传统 PC BIOS（基本输入输出系统）的现代替代品。它定义了操作系统与平台固件之间的软件接口。

### 发展历史

| 时期 | 技术 | 位数 | 地址空间 | 分区表 |
|-----|-----------|------|--------------|-----------|
| 1981-2010 | Legacy BIOS | 16 位 | 1 MB | MBR |
| 2000-2005 | EFI 1.0（Intel） | 32 位 | 4 GB | GPT |
| 2005-至今 | UEFI 2.x | 32/64 位 | 完整 | GPT |

### 与传统 BIOS 的关键区别

**Legacy BIOS：**
- 在 16 位实模式下运行
- 仅可寻址 1 MB 空间
- 使用中断 0x13 访问磁盘
- MBR 分区表（最大 2 TB 磁盘，4 个主分区）
- 引导代码位于 MBR 前 440 字节

**UEFI：**
- 在 32/64 位保护或长模式下运行
- 完整系统地址空间
- 基于协议（Protocol）的驱动模型
- GPT 分区表（最大 9.4 ZB，128 个分区）
- 原生支持 FAT32 文件系统
- Secure Boot 功能
- 可直接运行 UEFI 应用程序（.efi 文件）

## UEFI 启动流程

```
Power On
   │
   ▼
SEC (Security Phase)
   │
   ▼
PEI (EFI Pre-Initialization)
   │  - CPU initialization
   │  - Memory detection
   ▼
DXE (Driver Execution Environment)
   │  - Most hardware initialized
   │  - UEFI protocols registered
   ▼
BDS (Boot Device Selection)
   │  - Boot manager runs
   │  - Tries boot options
   ▼
TSL (Transient System Load)
   │  - UEFI Shell (if selected)
   │  - OS boot loader runs
   ▼
RT (Runtime Phase)
   │  - OS takes over
   │  - UEFI Runtime Services remain available
   ▼
AL (After Life)
   - System shutdown/hibernate
```

## UEFI 服务

### 启动服务（在 ExitBootServices 之前可用）
- **协议处理**：LocateProtocol、InstallProtocol 等
- **内存分配**：AllocatePool、FreePool、AllocatePages
- **事件/定时器**：CreateEvent、SetTimer、WaitForEvent
- **镜像加载**：LoadImage、StartImage
- **ExitBootServices**：将控制权移交给操作系统

### 运行时服务（ExitBootServices 之后可用）
- **变量服务**：GetVariable、SetVariable
- **时间服务**：GetTime、SetTime
- **复位服务**：ResetSystem
- **胶囊更新**：UpdateCapsule

## UEFI 应用程序

UEFI 应用程序是 PE32+（可移植可执行文件）格式的文件，扩展名为 `.efi`。它们在加载任何操作系统之前运行在 UEFI 环境中。

类型：
- **启动加载程序**：加载操作系统（如 GRUB2、Windows Boot Manager）
- **Shell 应用程序**：在 UEFI Shell 中运行（如文本编辑器、文件管理器）
- **诊断工具**：内存测试器、硬件信息
- **游戏**：如 UEFI_Contra！

### UEFI 应用程序入口点

```c
#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/PrintLib.h>

EFI_STATUS
EFIAPI
UefiMain(
    IN EFI_HANDLE           ImageHandle,
    IN EFI_SYSTEM_TABLE     *SystemTable
)
{
    Print(L"Hello from UEFI!\n");
    return EFI_SUCCESS;
}
```

## UEFI Shell

UEFI Shell 在 UEFI 环境中提供了一个命令行界面。命令包括：

| 命令 | 描述 |
|---------|-------------|
| `map` | 列出已映射的设备 |
| `fs0:`、`fs1:` | 切换到文件系统 |
| `ls` | 列出文件 |
| `cd` | 切换目录 |
| `edit` | 文本编辑器 |
| `Contra.efi` | 运行 Contra 游戏 |

## 参考文献

- [UEFI Specification](https://uefi.org/specs/UEFI/2.11/)
- [TianoCore EDK2](https://github.com/tianocore/edk2)
- [OSDev UEFI Wiki](https://wiki.osdev.org/UEFI)
