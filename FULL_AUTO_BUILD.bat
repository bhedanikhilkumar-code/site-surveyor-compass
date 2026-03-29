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
    echo [1/5] Downloading Flutter...
    cd /d C:\
    
    REM Download Flutter (using PowerShell for reliability)
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$progressPreference = 'silentlyContinue'; ^
        Invoke-WebRequest -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.0-stable.zip' ^
        -OutFile 'flutter.zip'; ^
        Expand-Archive -Path 'flutter.zip' -DestinationPath 'C:\' -Force; ^
        Remove-Item 'flutter.zip' -Force"
    
    if %ERRORLEVEL% neq 0 (
        echo ❌ Failed to download Flutter
        echo Please download manually from: https://flutter.dev/docs/get-started/install/windows
        pause
        exit /b 1
    )
    echo ✅ Flutter downloaded
) else (
    echo ✅ Flutter already exists at %FLUTTER_HOME%
)

echo.
echo [2/5] Running Flutter doctor...
call %FLUTTER_BIN%\flutter doctor

echo.
echo [3/5] Getting dependencies...
cd /d "C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass"
call %FLUTTER_BIN%\flutter pub get

echo.
echo [4/5] Building APK (this takes 10-15 minutes)...
call %FLUTTER_BIN%\flutter build apk --release -v

if %ERRORLEVEL% neq 0 (
    echo ❌ APK build failed
    pause
    exit /b 1
)

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║              ✅ BUILD SUCCESSFUL!                          ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📱 Your APK is ready at:
echo.
echo    build\app\outputs\flutter-apk\app-release.apk
echo.
echo 📊 File details:
dir /s "build\app\outputs\flutter-apk\app-release.apk"
echo.
echo 🎉 What to do next:
echo    1. Connect your Android phone via USB
echo    2. Run: flutter install --release
echo    3. App will install and launch automatically
echo.
echo 📤 Or share this APK with others:
echo    Copy the app-release.apk file and share it
echo.
pause
