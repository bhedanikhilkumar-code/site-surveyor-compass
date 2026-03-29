#!/bin/bash
# Site Surveyor Compass - Full Automated Build for macOS/Linux

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║     🚀 SITE SURVEYOR COMPASS - FULL AUTO BUILD 🚀         ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.16.0-stable.zip"
else
    echo "❌ Unsupported OS"
    exit 1
fi

echo "[1/4] Checking for Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "Downloading Flutter for $OS..."
    cd ~
    
    if [[ "$OS" == "linux" ]]; then
        wget -q $FLUTTER_URL -O flutter.tar.xz
        tar xf flutter.tar.xz
        rm flutter.tar.xz
    else
        curl -O $FLUTTER_URL
        unzip -q flutter.zip
        rm flutter.zip
    fi
    
    echo "export PATH=\"\$HOME/flutter/bin:\$PATH\"" >> ~/.bashrc
    source ~/.bashrc
    echo "✅ Flutter installed"
else
    echo "✅ Flutter already installed"
fi

echo ""
echo "[2/4] Running Flutter doctor..."
flutter doctor -v

echo ""
echo "[3/4] Getting dependencies..."
cd "C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass"
flutter pub get

echo ""
echo "[4/4] Building APK..."
flutter build apk --release

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ BUILD SUCCESSFUL!                          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📱 Your APK is ready at:"
echo "   build/app/outputs/flutter-apk/app-release.apk"
echo ""
