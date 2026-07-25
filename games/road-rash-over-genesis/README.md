# Sega Genesis / Mega Drive Emulation on DOS

Play Sega Genesis games inside DOSBox using **Genecyst**, a native DOS emulator.

## Directory Structure

```
road-rash-over-genesis/
  genecyst/              # Genecyst DOS emulator
    GENECYST.EXE          - Emulator executable
    DOS4GW.EXE            - DOS4GW protected-mode extender
    README.TXT            - Original documentation
  roms/
    roadrash.bin          - Road Rash (USA) ROM
  run.bat                 - Launch script for DOSBox
```

## How to Run

1. **Mount the directory in DOSBox:**

   ```
   mount c .
   c:
   ```

2. **Launch the game:**

   ```
   run.bat
   ```

   Or directly:
   ```
   cd genecyst
   genecyst -run ..\roms\roadrash.bin -version USA -hidegui
   ```

## Controls

| Key | Action |
|-----|--------|
| Arrow Keys | Direction |
| Z / Ctrl | Button A (accelerate) |
| X / Alt | Button B (brake) |
| C / Space | Button C (attack) |
| V | Start |
| A | Button X (kick) |
| S | Button Y (punch) |
| D | Button Z (weapon) |
| F5 | Save State |
| F7 | Load State |
| 0-9 | Select State Slot |
| Alt-L | Load ROM |
| Alt-S | Settings |
| Alt-Q | Quit |

## Notes

- **Performance:** Running a Genesis emulator inside DOSBox is emulation inception (DOSBox → x86 → Genecyst → 68000 → Genesis game). Set DOSBox cycles to max (Ctrl-F12) for best performance.
- **Sound:** Genecyst supports FM synthesis and PSG sound. If performance is poor, try `-nosound` flag.
- **ROM Format:** Genecyst supports BIN, SMD, and split formats.
- **Region:** `-version USA` sets the region. Available: USA, Japan, Europe.
- **Save States:** Press F5 to save, F7 to load. Use keys 0-9 to select slot.

## Emulator Evaluation

Genecyst (by Bloodlust Software, author of NESticle) was chosen for DOSBox because:

- **Lightest emulator** — written in assembly, optimized for 486/Pentium era
- **Lowest system requirements** — Pentium 8MB RAM minimum
- **Save state support** — F5/F7 quick save/load
- **Good compatibility** — ~80% of Genesis games work
- **DOS native** — no Windows/DirectX dependency

## ROM Information

| Field | Value |
|-------|-------|
| Game | Road Rash |
| Platform | Sega Genesis / Mega Drive |
| Year | 1991 |
| Developer | Electronic Arts |
| ROM Size | 786,432 bytes (6 megabit) |
| Format | BIN (raw) |
| Region | USA |
| Source | Internet Archive |
