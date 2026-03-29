@echo off
REM ============================================
REM COMPLETE SOLUTION: Build APK + Install on Device
REM ============================================

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║    🎯 BUILD & INSTALL - COMPLETE SOLUTION 🎯              ║
echo ║                                                            ║
echo ║  This script will:                                         ║
echo ║  1. Build release APK                                      ║
echo ║  2. Install on connected Android device                    ║
echo ║  3. Launch the app                                         ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Check Flutter
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter not installed
    echo.
    echo Run SETUP_FLUTTER.ps1 first to install Flutter and Android SDK
    echo.
    pause
    exit /b 1
)

REM Check Android device
echo [1/5] Checking for connected Android device...
where adb >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    adb devices
    echo.
)

REM Clean build
echo [2/5] Cleaning previous builds...
call flutter clean
echo ✅ Clean complete
echo.

REM Get dependencies
echo [3/5] Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Failed to get dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies ready
echo.

REM Build APK
echo [4/5] Building APK...
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo ❌ APK build failed
    pause
    exit /b 1
)
echo ✅ APK built successfully
echo.

REM Install on device
echo [5/5] Installing on device...
echo.
echo Connect your Android device and ensure USB debugging is enabled.
echo Press any key to continue...
pause >nul

call flutter install --release
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ╔════════════════════════════════════════════════════════════╗
    echo ║           ✅ INSTALLATION COMPLETE!                        ║
    echo ╚════════════════════════════════════════════════════════════╝
    echo.
    echo 🎉 App should now be running on your device!
    echo.
    echo If you don't see it:
    echo    1. Check "Allow installation from Unknown Sources"
    echo    2. Make sure USB Debugging is enabled
    echo    3. Try again with USB cable properly connected
) else (
    echo.
    echo ❌ Installation failed
    echo.
    echo Possible solutions:
    echo    1. Connect Android device via USB
    echo    2. Enable USB Debugging on device
    echo    3. Allow the computer on the USB Authorization dialog
    echo    4. Run as Administrator
)

echo.
pause
