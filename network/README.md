<p align="center">
  <a href="README.md"><img alt="English" height="30" src="https://img.shields.io/badge/English-3593D2?style=for-the-badge"></a>&nbsp;
  <a href="README.zh-CN.md"><img alt="简体中文" height="30" src="https://img.shields.io/badge/简体中文-7CB342?style=for-the-badge"></a>
</p>

# Network Setup in DOS — Microsoft Network Client 3.0

> Original article: [kompx.com](http://www.kompx.com/en/network-setup-in-dos-microsoft-network-client.htm)

In order to install Microsoft Network Client 3.0 and set up network in DOS, there have to be several programs at hand:

1. **Microsoft Network Client 3.0** — [`msnc3.0.rar`](msnc3.0.rar)
2. **NDIS 2.0 driver** for Ethernet network card (e.g. Realtek RTL8029AS) — [`ndis2-8029as.rar`](ndis2-8029as.rar)
3. **QEMM97** (if not using MS-DOS 6.0+) — [`qemm97.rar`](qemm97.rar)

---

## Setup and Installation

### 1. Prepare driver folder

Create a folder, e.g. `C:\DRIVERS\`, and place the NDIS 2.0 driver for your Ethernet card there.

### 2. Prepare installation floppies

Extract Microsoft Network Client 3.0 disk images:

```
DSK3-1.EXE -d A:
DSK3-2.EXE -d A:
```

### 3. Install Microsoft Network Client 3.0

Run `setup.exe` from the first floppy and follow the installer:

![Welcome screen](msnc-setup-1.jpg)

1. **Welcome** — Press Enter to continue

![Install path](msnc-setup-2.jpg)

2. **Install path** — Select folder (default `C:\NET` is fine)

![System examination](msnc-setup-3.jpg)

3. **Driver selection** — If your NIC is not listed, choose "*Network adapter not shown on list below..."

![Driver path](msnc-setup-4.jpg)

4. **Driver path** — Enter `C:\DRIVERS\`

![Select driver](msnc-setup-5.jpg)

5. **Select driver** — Pick your NIC from the list (e.g. `RTL8029AS PCI Ethernet Adapter`)

![Performance option](msnc-setup-6.jpg)

6. **Performance** — Choose whether to let MSCLIENT use more RAM for better performance

![User name](msnc-setup-7.jpg)

7. **User name** — Enter a name (up to 20 characters, e.g. `net`)

![Confirm settings](msnc-setup-8.jpg)

8. **Confirm** — Review and confirm settings, then files are copied to `C:\NET\`

![Copying files](msnc-setup-9.jpg)

9. Files are being copied

![Installation complete](msnc-setup-10.jpg)

10. Installation complete — press Enter to reboot

![Restart prompt](msnc-setup-11.jpg)

11. Press Enter to restart

### 4. First boot

After restart, Microsoft Network Client will prompt for:
- **User name** — Press Enter to use the name set during installation
- **Password** — Press Enter (no password set)
- **Create password?** — Press Enter to skip

### 5. Optimize base memory

Run `MemMaker` (MS-DOS) or `OPTIMIZE` (QEMM97) to optimize conventional memory. Press Enter at each prompt — the optimizer handles everything automatically. The computer will restart several times.

---

## Network Connection

Once setup is complete, the network connection is established automatically on each boot via Microsoft Network Client.

---

## Requirements

- MS-DOS 6.0+
- FreeDOS 1.0+
- Ethernet network card with NDIS 2.0 driver

---

## Contents

| File | Description |
|------|-------------|
| `msnc3.0.rar` | Microsoft Network Client 3.0 installation disks |
| `ndis2-8029as.rar` | NDIS 2.0 driver for Realtek RTL8029AS PCI Ethernet Adapter |
| `qemm97.rar` | QEMM97 memory manager (for non-MS-DOS 6.0+ systems) |

---

## References

- [Original article on kompx.com](http://www.kompx.com/en/network-setup-in-dos-microsoft-network-client.htm)
- [Arachne web browser — installing and setting up for internet via Ethernet](http://www.kompx.com/en/arachne-installing-and-setting-up-ethernet.htm)
- [FTP in DOS](http://www.kompx.com/en/ftp-in-dos.htm)
