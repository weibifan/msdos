<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# QEMU 1.2 中的 MS-DOS 6.22

预配置的 QEMU 虚拟机，已安装 MS-DOS 6.22。

## 文件

- **myimage.zip** — 压缩的 QEMU 磁盘镜像，包含：
  - 已安装 MS-DOS 6.22 的虚拟硬盘
  - 预配置的 BIOS 和 VM 设置

## 快速开始

1. 解压 myimage.zip
2. 使用 QEMU 启动：

`ash
qemu-system-x86_64 -m 64 -drive file=myimage.img,format=raw
`

## VM 规格

| 组件 | 详情 |
|------|------|
| CPU | 1 vCPU |
| 内存 | 64 MB |
| 存储 | 200 MB IDE 磁盘 |
| 网络 | 无 |
| 声卡 | PC 扬声器 |
| 显卡 | 标准 VGA |

## 创建全新的 VM

如果需要从头构建新的 MS-DOS VM：

`ash
qemu-img create -f raw dos_hd.img 200M
qemu-system-x86_64 -m 64 \
  -drive file=dos_hd.img,format=raw \
  -fda dos622.img
`

## 资源

- [QEMU 文档](https://www.qemu.org/documentation/)
- [QEMU x86 模拟参考](https://wiki.qemu.org/Documentation/Platforms/PC)