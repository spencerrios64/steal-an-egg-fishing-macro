@echo off
setlocal
title Steal An Egg fishing macro - updater
cd /d "%~dp0"

set "BASE=https://raw.githubusercontent.com/spencerrios64/steal-an-egg-fishing-macro/main"
set "FAIL=0"

echo.
echo  Updating the fishing macro from GitHub...
echo  (close the macro first if it is running)
echo.

for %%F in (steal_an_egg_fishing.ahk steal_an_egg_fishing.ps1 run_fishing.bat README.md) do call :get %%F

echo.
if "%FAIL%"=="0" (
    echo  Done. Your old files were kept as *.bak
    echo  Note: settings you changed are reset to the defaults - copy them
    echo  over from the .bak file if you want to keep them.
    echo  Start the macro again to use the new version.
) else (
    echo  Some files could not be downloaded. Check your internet connection
    echo  and try again. Files that failed were left unchanged.
)
echo.
pause
exit /b

:get
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -UseBasicParsing -Uri '%BASE%/%1' -OutFile '%1.new' -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo   FAILED   %1
    set "FAIL=1"
    if exist "%1.new" del "%1.new" >nul 2>&1
    goto :eof
)
if exist "%1" copy /y "%1" "%1.bak" >nul
move /y "%1.new" "%1" >nul
echo   Updated  %1
goto :eof
