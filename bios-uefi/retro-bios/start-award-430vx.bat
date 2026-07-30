@echo off
setlocal
set QEMU=qemu-system-x86_64.exe
set DIR=%~dp0
set BIOS=%DIR%award\430vx.bin

if not exist "%BIOS%" echo BIOS not found & pause & exit /b 1

echo.
echo === Award 430VX BIOS (Pentium, ~1996) ===
echo Press DEL repeatedly after window opens to enter BIOS setup
echo.
%QEMU% -bios "%BIOS%" -cpu pentium -m 32 -machine pc,accel=tcg -vga std -display gtk -rtc base=1996-06-01 -net none
pause
