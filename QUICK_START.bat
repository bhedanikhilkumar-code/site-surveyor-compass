@echo off
REM ============================================
REM QUICK START - Everything in One Script
REM ============================================

title Site Surveyor Compass - Quick Start

color 0A

cls
echo.
echo.
echo           ██████╗ ██╗   ██╗██╗ ██████╗██╗  ██╗    ███████╗████████╗ █████╗ ██████╗ ████████╗
echo           ██╔═══██╗██║   ██║██║██╔════╝██║ ██╔╝    ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝
echo           ██║   ██║██║   ██║██║██║     █████╔╝     ███████╗   ██║   ███████║██████╔╝   ██║
echo           ██║▄▄██║██║   ██║██║██║     ██╔═██╗     ╚════██║   ██║   ██╔══██║██╔══██╗   ██║
echo           ╚██████╔╝╚██████╔╝██║╚██████╗██║  ██╗    ███████║   ██║   ██║  ██║██║  ██║   ██║
echo            ╚══▀▀═╝  ╚═════╝ ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
echo.
echo                            COMPASS
echo.
echo.
echo                    What would you like to do?
echo.
echo                  1. Setup Flutter ^& Android SDK
echo                  2. Build APK only
echo                  3. Build ^& Install APK
echo                  4. Clean project
echo                  5. Check Flutter status
echo                  6. Open project in editor
echo                  7. Exit
echo.
echo.

set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto setup
if "%choice%"=="2" goto build
if "%choice%"=="3" goto buildinstall
if "%choice%"=="4" goto clean
if "%choice%"=="5" goto doctor
if "%choice%"=="6" goto editor
if "%choice%"=="7" goto end

echo Invalid choice. Please try again.
timeout /t 2
cls
goto :start

:setup
cls
echo.
echo Starting Flutter setup...
echo.
powershell -ExecutionPolicy Bypass -File "SETUP_FLUTTER.ps1"
goto :start

:build
cls
echo.
echo Building APK...
echo.
call BUILD_APK.bat
goto :start

:buildinstall
cls
echo.
echo Building and installing...
echo.
call BUILD_AND_INSTALL.bat
goto :start

:clean
cls
echo.
echo Cleaning project...
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    call flutter clean
    echo ✅ Project cleaned
) else (
    echo ❌ Flutter not found
)
timeout /t 3
goto :start

:doctor
cls
echo.
where flutter >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    call flutter doctor -v
) else (
    echo ❌ Flutter not installed yet
    echo Run option 1 first to setup Flutter
    timeout /t 3
)
goto :start

:editor
cls
echo Opening project...
start %cd%
timeout /t 2
goto :start

:end
echo.
echo Goodbye!
timeout /t 2
exit

:start
cls
goto :loop
