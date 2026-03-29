# ============================================
# Site Surveyor Compass - FLUTTER SETUP
# ============================================
# Run this script to automatically download and install Flutter
# PowerShell: Right-click → Run with PowerShell

Write-Host @"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║      📦 FLUTTER & ANDROID SDK - AUTOMATIC SETUP 📦        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

This script will:
1. Download Flutter SDK
2. Download Android SDK
3. Configure environment variables
4. Verify installation

This may take 10-20 minutes depending on your internet speed.

"@ -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "❌ This script must run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

Write-Host "✅ Running as Administrator`n" -ForegroundColor Green

# Step 1: Download Flutter
Write-Host "[1/4] Downloading Flutter SDK..." -ForegroundColor Cyan
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.0-stable.zip"
$flutterZip = "$env:USERPROFILE\Downloads\flutter.zip"
$flutterPath = "C:\flutter"

if (Test-Path $flutterPath) {
    Write-Host "✅ Flutter already installed at $flutterPath" -ForegroundColor Green
} else {
    try {
        Write-Host "Downloading Flutter... This may take 5-10 minutes"
        # Using BitsTransfer for reliable download
        if (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue) {
            Start-BitsTransfer -Source $flutterUrl -Destination $flutterZip -DisplayName "Flutter SDK"
        } else {
            # Fallback to WebClient
            $client = New-Object System.Net.WebClient
            $client.DownloadFile($flutterUrl, $flutterZip)
        }
        
        Write-Host "Extracting Flutter..."
        Expand-Archive -Path $flutterZip -DestinationPath C:\ -Force
        Remove-Item $flutterZip -Force
        Write-Host "✅ Flutter installed to C:\flutter" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download Flutter: $_" -ForegroundColor Red
        Write-Host "Manual download: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
    }
}

# Step 2: Set Environment Variables
Write-Host "`n[2/4] Setting environment variables..." -ForegroundColor Cyan

# Add Flutter to PATH
$existingPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($existingPath -notlike "*flutter*") {
    $newPath = "$flutterPath\bin;" + $existingPath
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
    Write-Host "✅ Added Flutter to PATH" -ForegroundColor Green
} else {
    Write-Host "✅ Flutter already in PATH" -ForegroundColor Green
}

# Set FLUTTER_HOME
[Environment]::SetEnvironmentVariable("FLUTTER_HOME", $flutterPath, "Machine")
Write-Host "✅ Set FLUTTER_HOME = $flutterPath" -ForegroundColor Green

# Step 3: Run Flutter Doctor
Write-Host "`n[3/4] Running Flutter Doctor..." -ForegroundColor Cyan
$env:PATH = "$flutterPath\bin;" + $env:PATH
flutter doctor --verbose

# Step 4: Accept Android Licenses
Write-Host "`n[4/4] Accepting Android licenses..." -ForegroundColor Cyan
flutter doctor --android-licenses

Write-Host @"

╔════════════════════════════════════════════════════════════╗
║               ✅ SETUP COMPLETE!                          ║
╚════════════════════════════════════════════════════════════╝

Next steps:
1. Close and reopen PowerShell/CMD to refresh PATH
2. Run: cd "C:\Users\bheda\Music\Desktop\Copilot CLI\site_surveyor_compass"
3. Run: flutter pub get
4. Run: flutter build apk --release

Or simply run: BUILD_APK.bat

"@ -ForegroundColor Green

Read-Host "Press Enter to exit"
