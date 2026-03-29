@echo off
REM ============================================
REM Site Surveyor Compass - ONE-CLICK APK BUILDER
REM ============================================

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                                                            ║
echo ║   🚀 SITE SURVEYOR COMPASS - APK BUILD AUTOMATION 🚀       ║
echo ║                                                            ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Check if Flutter is installed
echo [1/4] Checking Flutter installation...
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter not found in PATH
    echo.
    echo Please install Flutter from https://flutter.dev/docs/get-started/install/windows
    echo And add C:\flutter\bin to your PATH environment variable
    echo.
    pause
    exit /b 1
)

echo ✅ Flutter found
flutter --version
echo.

REM Check if Android SDK is installed
echo [2/4] Checking Android SDK installation...
if not defined ANDROID_HOME (
    echo ⚠️  ANDROID_HOME environment variable not set
    echo Please set ANDROID_HOME to your Android SDK location
    echo Usually: C:\Users\%USERNAME%\AppData\Local\Android\sdk
    pause
    exit /b 1
)

echo ✅ Android SDK: %ANDROID_HOME%
echo.

REM Get dependencies
echo [3/4] Getting Flutter dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Failed to get dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies installed
echo.

REM Build APK
echo [4/4] Building APK (this will take 5-15 minutes)...
echo.
call flutter build apk --release -v
if %ERRORLEVEL% NEQ 0 (
    echo ❌ APK build failed
    pause
    exit /b 1
)

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║                   ✅ BUILD SUCCESSFUL!                    ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo 📱 APK Location:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
echo 📦 File Size: 
dir /s build\app\outputs\flutter-apk\app-release.apk
echo.
echo 🚀 Next Steps:
echo    1. Connect your Android device
echo    2. Run: flutter install --release
echo    3. Or manually install the APK on your device
echo.
pause
