<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# 启动盘合集

MS-DOS 和 Windows 9x 时代的可启动磁盘镜像合集。

## 镜像

| 文件 | 内容 | 用途 |
|------|---------|---------|
| ms-dos-622.img | MS-DOS 6.22 | 标准 DOS 启动盘 |
| ms-dos-rescue.img | DOS 救援盘 | 系统救援与恢复 |
| win95.img | Windows 95 | Windows 95 启动盘 |
| win98se.img | Windows 98 SE | Windows 98 第二版启动盘 |

## 工具

| 文件 | 说明 |
|------|-------------|
| hd-copy.exe | HD-COPY v2.3R — 快速软盘复制/映像工具，支持非标准格式、快速格式化、驱动器清洁、病毒清除和坏道修复 |
| undisk.exe | UNDISK v1.6 — 磁盘镜像提取工具，支持多种软盘镜像格式 |
| undiskp.exe | UNDISKP v1.95 — 增强版，支持长文件名和更多镜像格式 |

## 使用

**写入镜像到真实软盘：**

```bash
hd-copy.exe dos622.img
```

**从软盘提取镜像文件：**

```bash
undisk.exe A: output.img
```

## 说明

- 所有镜像均为 1.44 MB（标准高密度软盘格式）
- 可用于真实软驱、模拟器（QEMU、VirtualBox、VMware）或虚拟软盘工具
