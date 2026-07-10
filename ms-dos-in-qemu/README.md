# MS-DOS 6.22 in QEMU 1.2

Pre-configured QEMU virtual machine with MS-DOS 6.22 installed.

## Files

- **myimage.zip** — Compressed QEMU disk image containing:
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
