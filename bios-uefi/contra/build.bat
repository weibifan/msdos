@echo off
REM Build Contra.efi from source using EDK2 + VS2019
REM Prerequisites:
REM   1. Visual Studio 2019 (or 2022) with C++ tools
REM   2. EDK2 cloned from https://github.com/tianocore/edk2
REM   3. NASM installed and in PATH
REM   4. Python 3.x installed

echo ============================================
echo Building UEFI_Contra - Contra.efi
echo ============================================
echo.
echo This build requires:
echo   - Visual Studio 2019/2022 (Build Tools)
echo   - EDK2 (edk2-stable202502 or later)
echo   - NASM
echo   - Python 3.x
echo.
echo Full build instructions:
echo.
echo 1. Clone EDK2:
echo    git clone https://github.com/tianocore/edk2.git
echo    cd edk2
echo    git submodule update --init
echo.
echo 2. Set up build environment:
echo    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
echo.
echo 3. Set variables:
echo    set NASM_PREFIX=C:\Program Files\NASM\
echo    set EDK_TOOLS_PATH=%%WORKSPACE%%\BaseTools
echo    set PYTHON_COMMAND=python
echo.
echo 4. Build BaseTools:
echo    nmake -f BaseTools\Makefile
echo.
echo 5. Copy contra-uefi source to EDK2:
echo    xcopy /E /I %~dp0contra-uefi\src edk2\EmulatorPkg\Application\ContraGame\
echo.
echo 6. Build:
echo    build -p EmulatorPkg\EmulatorPkg.dsc ^
echo          -m EmulatorPkg\Application\ContraGame\ContraGame.inf ^
echo          -a X64 -t VS2019 -b DEBUG
echo.
echo 7. Copy output:
echo    copy Build\EmulatorX64\DEBUG_VS2019\X64\Contra.efi %~dp0
echo.
echo ============================================
echo.
echo NOTE: A full EDK2 build environment is required.
echo See https://github.com/tianocore/edk2 for setup guide.
echo.
pause
