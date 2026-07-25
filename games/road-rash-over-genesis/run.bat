@echo off
echo ============================================
echo  Genecyst - Sega Genesis Emulator for DOS
echo  Game: Road Rash (1991, Electronic Arts)
echo ============================================
echo.
echo  Controls:
echo  Arrow Keys - Direction
echo  Z/Ctrl     - Button A (accelerate)
echo  X/Alt      - Button B (brake)
echo  C/Space    - Button C (attack)
echo  V          - Start
echo  A          - Button X (kick)
echo  S          - Button Y (punch)
echo  D          - Button Z (weapon)
echo.
echo  Alt-L  Load ROM    Alt-S  Settings
echo  F5     Save State  F7     Load State
echo  0-9    Select State Slot
echo.
echo ============================================
cd genecyst
genecyst.exe -run ..\roms\roadrash.bin -version USA -hidegui
cd ..
