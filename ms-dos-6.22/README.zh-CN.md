<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# MS-DOS 6.22

MS-DOS 6.22 安装盘、镜像及相关资源。

## Files

| File | Description |
|------|-------------|
| `MS-DOS 6.22.iso` | MS-DOS 6.22 完整安装光盘镜像 |
| `disk1.img` | 安装盘 1 |
| `disk2.img` | 安装盘 2 |
| `disk3.img` | 安装盘 3 |
| `Suppdisk.img` | Supplemental disk — 补充工具盘 |
| `DOS622SC.zip` | MSDN 简体中文版 DOS 6.22 安装程序（SC_MSDOS622sc.exe 解压后打包） |
| `screenshot.png` | 安装截图 |
| `install(chinese voice).mp4` | 安装过程录像（中文语音解说）<br><video src="install(chinese%20voice).mp4" controls width="320"></video> |

## Quick Start

### 在 QEMU 中使用 ISO 安装

```bash
qemu-system-x86_64 -m 64 -cdrom "MS-DOS 6.22.iso"
```

### 使用软盘镜像安装

```bash
qemu-system-x86_64 -m 64 -fda disk1.img -fdb disk2.img
```

### 在 DOSBox 中挂载 ISO

```bash
imgmount d "MS-DOS 6.22.iso" -t cdrom
d:
setup
```

## Notes

- 软盘镜像共 3 张安装盘 + 1 张补充盘，均为 1.44 MB 标准格式
- `DOS622SC.zip` 包含的是 MSDN 渠道的简体中文版，直接解压后运行 SETUP.EXE 即可安装
- ISO 镜像可直接在大部分虚拟机（QEMU / VirtualBox / VMware）中使用
