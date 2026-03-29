# Flutter SDK Download Script
# This script downloads and extracts Flutter SDK to C:\flutter

$FlutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.0-stable.zip"
$DownloadPath = "C:\flutter_windows_3.16.0-stable.zip"
$ExtractPath = "C:\"

Write-Host "📥 Downloading Flutter SDK..." -ForegroundColor Green
Write-Host "This may take 5-10 minutes depending on your internet speed..." -ForegroundColor Yellow
Write-Host ""

try {
    # Download Flutter
    Write-Host "Downloading from: $FlutterUrl" -ForegroundColor Cyan
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    
    $ProgressPreference = 'Continue'
    Invoke-WebRequest -Uri $FlutterUrl -OutFile $DownloadPath -UseBasicParsing
    
    Write-Host "✅ Download complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Extracting Flutter SDK..." -ForegroundColor Green
    
    # Extract Flutter
    Expand-Archive -Path $DownloadPath -DestinationPath $ExtractPath -Force
    
    Write-Host "✅ Extraction complete!" -ForegroundColor Green
    
    # Clean up
    Remove-Item $DownloadPath -Force
    
    Write-Host "✅ Flutter SDK ready at C:\flutter" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible solutions:" -ForegroundColor Yellow
    Write-Host "1. Check your internet connection" -ForegroundColor Yellow
    Write-Host "2. Try running the script again" -ForegroundColor Yellow
    Write-Host "3. Download Flutter manually from https://flutter.dev" -ForegroundColor Yellow
    exit 1
}
