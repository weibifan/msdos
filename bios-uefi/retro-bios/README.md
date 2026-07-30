# Early BIOS ROM Collection & Demo

This directory contains real BIOS ROMs from 1986-2001, loaded via QEMU's `-bios` flag.

## Known Limitations

- QEMU 11.0.0 GTK display on Windows **cannot render VGA text mode 03h** (black screen)
- SDL and EGL+VNC backends crash on this system (access violation)
- curses display has CP437 to GBK encoding issues on Chinese Windows
- Only **Award i815** (Pentium III) completes POST and shows visible output on this setup
- Text-mode BIOS ROMs execute POST (confirmed via CPU debug log) but cannot be displayed

## BIOS List

| # | Name | Vendor | Era | Size | Display | Enter Setup |
|---|------|--------|-----|------|---------|-----------|
| 1 | Award i815 | Award | ~2000 | 256KB | **works** | Del |
| 2 | Award 430VX | Award | ~1996 | 128KB | untested | Del |
| 3 | Award w6337ims | Award | ~2001 | 256KB | black (SiS chipset mismatch) | Del |

## Usage

### Prerequisites

- QEMU 11.0.0+ in PATH

### Launch

**Award i815 (works):**
```
start-award-i815.bat
```



## Display Backend Status

| Backend | Result |
|---------|--------|
| `-display gtk` | black screen for text mode, works for Award i815 graphics mode |
| `-display sdl` | access violation crash |
| `-display curses` | functional but fails to convert CP437 glyphs on GBK console |
| `-display egl-headless -vnc :0` | access violation crash |

Recommendation: use a different emulator (86Box, PCem) for text-mode-only BIOS ROMs.

## File Structure

```
retro-bios/
├── award/
│   ├── 430vx.bin
│   ├── i815.bin
│   └── w6337ims.740
├── start-award-430vx.bat
├── start-award-i815.bat
├── start-award-w6337ims.bat
└── README.md
```

## References

- [PCem BIOS Bundle (GitHub - Abdess/retrobios)](https://github.com/Abdess/retrobios)
- [Award BIOS for QEMU (GitHub - Hunterrules0-0)](https://github.com/Hunterrules0-0/Award-bioses-for-qemu)
- [SeaBIOS](https://www.seabios.org/)
- [Wim's BIOS](https://www.wimsbios.com/)
