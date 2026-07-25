# Sokoban — DOS Port

> Classic Sokoban puzzle game ported to MS-DOS.
>
> Original source: [bravegnu/sokoban](https://github.com/bravegnu/sokoban) — GPL License.

## How to Play

Use **Arrow Keys** to move the worker (`@`). Push all boxes (`$`) onto docks (`.`) to clear each level.

| Key | Action |
|-----|--------|
| `↑ ↓ ← →` | Move worker |
| `R` | Restart level |
| `S` | Skip level |
| `Q` | Quit |

## Quick Start

**Option 1: Double-click `start.bat`** — launches DOSBox with everything mounted.

**Option 2: Manual**

```bash
dosbox -conf sokoban.conf
# Then in DOSBox:
C:\> build   # Compile
C:\> sokoban # Play
```

## Files

```
sokoban-dos/
├── README.md                  # This file
├── SOKOBAN.EXE                # Pre-compiled DOS executable
├── levels.txt                 # 50 puzzle levels
├── build.bat                  # One-step build script
├── start.bat                  # DOSBox launcher (Windows)
├── sokoban.conf               # DOSBox config
│
├── src/                       # Source code (Turbo C 2.0)
│   ├── main.c                 # Entry point / game loop
│   ├── world.c / world.h      # World state
│   ├── game_eng.c / .h        # Game logic (movement, win conditions)
│   ├── lvl_pars.c / .h        # Level file parser
│   ├── dos-view.c / .h        # DOS console view (conio.h)
│   ├── view.h                 # View interface
│   ├── log.c / log.h          # Logging (DOS-compatible)
│   └── dosdefs.h              # Turbo C compatibility (bool, true, false)
│
├── tc/                        # Turbo C 2.0 extracted from TC2.img
│   ├── TCC.EXE                # Command-line compiler
│   ├── TLINK.EXE              # Linker
│   ├── INCLUDE/               # C header files
│   └── LIB/                   # Library files
│
└── extract-tcc.py             # Script to extract TCC from TC2.img
```

## Build Notes

- Compiled with **Turbo C 2.0** (small memory model)
- Source files use **short 8.3 names** for DOS compatibility
- All files have **CRLF line endings** (required by Turbo C)
- `dosdefs.h` provides `bool`/`true`/`false` (not in Turbo C)
- No variadic macros (not supported by Turbo C)
- `strftime()` replaced with `sprintf()` + `struct tm`

## Credits

- Original game by [bravegnu](https://github.com/bravegnu/sokoban)
- DOS port by Bifan Wei
- License: GPL
