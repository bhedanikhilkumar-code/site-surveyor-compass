@echo off
REM ============================================
REM AUTOMATED APK BUILD - ONE COMMAND SOLUTION
REM ============================================
REM This script downloads everything and builds your APK
REM Run this as Administrator

setlocal enabledelayedexpansion

title Automated APK Build

cls
color 0A

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║     🚀 SITE SURVEYOR COMPASS - FULL AUTO BUILD 🚀         ║
echo ║                                                            ║
echo ║  This script will:                                         ║
echo ║  1. Download Flutter SDK (if needed)                       ║
echo ║  2. Configure Android environment                          ║
echo ║  3. Build your APK                                         ║
echo ║                                                            ║
echo ║  Estimated time: 40-60 minutes                             ║
echo ║  Internet required: YES                                    ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Check administrator rights
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ This script requires Administrator rights
    echo Please right-click and select "Run as Administrator"
    pause
    exit /b 1
)

echo ✅ Running as Administrator
echo.
echo Starting build process...
echo.

REM Set Flutter home
set FLUTTER_HOME=C:\flutter
set FLUTTER_BIN=%FLUTTER_HOME%\bin
set PATH=%FLUTTER_BIN%;%PATH%

REM Check if Flutter exists
if not exist "%FLUTTER_HOME%" (
    echo [1/5] Downloading Flutter SDK...
    echo This may take 5-10 minutes. Please be patient...
    echo.
    cd /d C:\
    
    REM Download Flutter using PowerShell (in separate file to avoid escaping issues)
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0download_flutter.ps1"
    
    if %ERRORLEVEL% neq 0 (
        echo ❌ Failed to download Flutter
        echo.
        echo Please download manually:
        echo 1. Go to: https://flutter.dev/docs/get-started/install/windows
        echo 2. Download Flutter SDK for Windows
        echo 3. Extract to: C:\flutter
        echo 4. Run this script again
        pause
        exit /b 1
    )
    echo ✅ Flutter downloaded and extracted
) else (
    echo ✅ Flutter already exists at %FLUTTER_HOME%
)

echo.
echo [2/5] Running Flutter doctor...
call "%FLUTTER_BIN%\flutter.bat" doctor
if %ERRORLEVEL% neq 0 (
    echo ⚠️  Flutter doctor reported issues (this is usually OK)
)

echo.
echo [3/5] Getting dependencies...
cd /d "%~dp0"
call "%FLUTTER_BIN%\flutter.bat" pub get
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to get dependencies
    echo Make sure you're connected to the internet
    pause
    exit /b 1
)
echo ✅ Dependencies downloaded

echo.
echo [4/5] Building APK (this takes 10-15 minutes)...
echo ⏳ Please wait... Building...
call "%FLUTTER_BIN%\flutter.bat" build apk --release

if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ APK build failed
    echo.
    echo Possible solutions:
    echo 1. Make sure you have at least 10 GB free disk space
    echo 2. Check your internet connection
    echo 3. Try running the script again
    pause
    exit /b 1
)

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║              ✅ BUILD SUCCESSFUL!                          ║
echo ║                                                            ║
echo ║  Your APK is ready! 🎉                                     ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📱 Your APK location:
echo.
echo    %~dp0build\app\outputs\flutter-apk\app-release.apk
echo.
echo 📊 File details:
if exist "%~dp0build\app\outputs\flutter-apk\app-release.apk" (
    for %%A in ("%~dp0build\app\outputs\flutter-apk\app-release.apk") do (
        echo    File size: %%~zA bytes
        echo    Path: %%~dpA
    )
)
echo.
echo 🎉 What to do next:
echo.
echo    Option 1: Install on your Android phone
echo    ├─ Connect phone via USB
echo    └─ Run: flutter install --release
echo.
echo    Option 2: Share with others
echo    ├─ Find the APK file above
echo    ├─ Share via Email, WhatsApp, Google Drive, etc.
echo    └─ They can install it on their Android device
echo.
echo    Option 3: Upload to Google Play Store
echo    ├─ Go to: https://play.google.com/console
echo    ├─ Create new app
echo    └─ Upload this APK
echo.
echo ════════════════════════════════════════════════════════════
echo.
pause
