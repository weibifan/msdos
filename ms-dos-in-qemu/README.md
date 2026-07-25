<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>
# MS-DOS 6.22 in QEMU 1.2

Pre-configured QEMU virtual machine with MS-DOS 6.22 installed.

## Files

- **myimage.zip** 鈥?Compressed QEMU disk image containing:
  - Virtual hard disk with MS-DOS 6.22 installed
  - Pre-configured BIOS and VM settings

## Quick Start

1. Extract `myimage.zip`
2. Boot with QEMU:

```bash
qemu-system-x86_64 -m 64 -drive file=myimage.img,format=raw
```

## VM Specifications

| Component | Detail |
|-----------|--------|
| CPU | 1 vCPU |
| RAM | 64 MB |
| Storage | 200 MB IDE disk |
| Networking | None (MS-DOS has no native TCP/IP) |
| Sound | PC speaker |
| Graphics | Standard VGA |

## Creating a Fresh VM

If you need to build a new MS-DOS VM from scratch:

```bash
qemu-img create -f raw dos_hd.img 200M
qemu-system-x86_64 -m 64 \
  -drive file=dos_hd.img,format=raw \
  -fda dos622.img
```

## Resources

- [QEMU Documentation](https://www.qemu.org/documentation/)
- [QEMU x86 emulation reference](https://wiki.qemu.org/Documentation/Platforms/PC)
