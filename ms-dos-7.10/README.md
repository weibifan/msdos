<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# MS-DOS 7.10

The final version of MS-DOS, released as part of Windows 98 Second Edition (1998). Supports FAT32 and large disk drives.

## Files

| File | Description |
|------|-------------|
| `ms-dos-71-disk1.zip` | Installation Disk 1 — setup files and core system |
| `ms-dos-71-disk2.zip` | Installation Disk 2 — additional utilities and drivers |
| `ms-dos-71-boot.zip` | Boot Disk — bootable floppy disk image |
| `ms-dos-71-boot-bd.zip` | Boot Disk — with additional tools |

## Notes

- MS-DOS 7.10 was never sold as a standalone retail product. It is the DOS kernel component bundled with Windows 95 OSR2 and Windows 98 SE.
- Key advantage over 6.22: native FAT32 support, breaking the 2 GB partition limit and better large memory management.
- Unlike MS-DOS 8.0 (Windows Me kernel), 7.10 retains full real-mode DOS support.
- For reliable memory configuration, manual DEVICEHIGH directives in CONFIG.SYS are recommended over MemMaker auto-configuration.
- DOS cannot recognize NTFS partitions. Dual-boot setups rely on the NT boot loader (NTLDR) chain-loading the DOS boot sector.
