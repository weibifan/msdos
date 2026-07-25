@echo off
setlocal
set QEMU=C:\Program Files\qemu\qemu-system-x86_64.exe
set GAME_DIR=%~dp0super-mario
set OVMF=%~dp0OVMF\OVMF_CODE.fd

if not exist "%QEMU%" (
    echo QEMU not found at %QEMU%
    pause
    exit /b 1
)

echo Starting QEMU + Super Mario Bros UEFI...
"%QEMU%" -drive if=pflash,format=raw,file="%OVMF%" -drive file=fat:rw:%GAME_DIR%,format=raw -m 256 -net none -display gtk
pause
