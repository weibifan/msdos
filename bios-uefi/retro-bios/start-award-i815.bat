@echo off
setlocal
set QEMU=qemu-system-x86_64.exe
set DIR=%~dp0
set BIOS=%DIR%award\i815.bin

if not exist "%BIOS%" echo BIOS not found & pause & exit /b 1

echo.
echo === Award i815 BIOS (Pentium III, ~2000) ===
echo Press DEL repeatedly after window opens to enter BIOS setup
echo.
%QEMU% -bios "%BIOS%" -cpu pentium3 -m 64 -machine pc,accel=tcg -vga std -display gtk -rtc base=2000-01-01 -net none
pause
