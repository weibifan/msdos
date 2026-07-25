@echo off
echo ========================
echo Building Sokoban for DOS
echo ========================
echo.
c:
cd \src
path c:\tc;%path%

echo Compiling...
..\tc\tcc -c -ms -I. -I..\tc\include world.c game_eng.c lvl_pars.c log.c dos-view.c main.c

echo Linking...
..\tc\tcc -ms -L..\tc\lib world.obj game_eng.obj lvl_pars.obj log.obj dos-view.obj main.obj
if errorlevel 1 goto err

ren world.exe sokoban.exe
copy sokoban.exe ..
cd \
echo.
echo SUCCESS! Type: SOKOBAN to play
goto end
:err
echo BUILD FAILED
:end
