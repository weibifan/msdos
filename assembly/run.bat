@echo off
cd /d "%~dp0"
where dosbox >nul 2>nul
if errorlevel 1 (
    echo dosbox not found. Please install DOSBox or add it to PATH.
    echo.
    echo Download: https://www.dosbox.com/download.php?main=1
    echo.
    pause
    exit /b 1
)
dosbox -c "mount c .." -c "c:" -c "cd assembly"
