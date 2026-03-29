# Site Surveyor Compass 🧭

A precision-focused **digital compass mobile app** built with Flutter for construction site surveying and site planning. 

## Features

### 🧭 High-Precision Compass Dial
- Real-time bearing display with magnetic and true north indicators
- Cardinal and ordinal directions with degree readouts
- Smooth bearing updates using low-pass filtering
- Red needle for magnetic bearing, blue dashed line for true north

### 📐 Digital Bubble Level
- Integrated level using device accelerometer
- Pitch and roll measurements for surface calibration
- Visual bubble indicator showing device orientation
- Green when level (<2°), orange when tilted

### 📍 Waypoint Manager (Coming Soon)
- Save specific directional headings with GPS coordinates
- Custom notes for each waypoint
- Local storage with Hive
- View and manage saved survey points

### ⚙️ Advanced Settings
- Magnetic declination adjustment for location-specific calibration
- Compass calibration mode
- Toggle between magnetic and true north display

## Project Structure

```
lib/
├── main.dart                  # App entry point with providers
├── models/
│   └── waypoint_model.dart   # Waypoint data model for Hive storage
├── providers/
│   └── compass_provider.dart # State management for sensors & compass logic
├── screens/
│   ├── home_screen.dart      # Main compass UI with all controls
│   └── waypoint_screen.dart  # Coming soon
├── services/
│   ├── gps_service.dart      # GPS location tracking
│   └── sensor_service.dart   # Sensor data handling
├── widgets/
│   └── compass_dial.dart     # Custom compass dial painter widget
└── utils/
    └── constants.dart         # App constants and configurations
```

## Getting Started

### Prerequisites
- Flutter SDK >= 3.0.0
- Xcode (iOS) or Android Studio (Android)
- Android SDK (API 34+)
- Java JDK (version 11+)

### Installation

1. **Get dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on emulator/device**:
   ```bash
   flutter run
   ```

3. **Build for release**:
   ```bash
   flutter build apk      # Android
   flutter build ios      # iOS
   ```

### Automated Build (Recommended)

For automated APK building with zero setup:

**Windows**:
```bash
# Run the automated build script (downloads Flutter & Android SDK automatically)
FULL_AUTO_BUILD.bat
```

**macOS/Linux**:
```bash
chmod +x full-auto-build.sh
./full-auto-build.sh
```

**Build Options**:
- `FULL_AUTO_BUILD.bat` - Complete automation (downloads SDKs)
- `BUILD_APK.bat` - Build only (requires Flutter/Android SDK)
- `QUICK_START.bat` - Interactive menu with 7 options
- `BUILD_AND_INSTALL.bat` - Build + install to connected device

**Documentation**:
- `STEP_BY_STEP_GUIDE.md` - Detailed step-by-step guide (Hindi/English)
- `VISUAL_WALKTHROUGH.txt` - Visual walkthrough with ASCII diagrams
- `QUICK_REFERENCE.txt` - Quick reference card
- `APK_BUILD_NOW.md` - Build guide
- `KAHA_RUN_KARU.md` - Where to run (Hindi)

## Dependencies

- **provider**: State management
- **sensors_plus**: Magnetometer and accelerometer access
- **geolocator**: GPS functionality
- **hive**: Local database for waypoints
- **fl_chart**: Data visualization (future enhancement)
- **permission_handler**: Sensor/GPS permissions

## Sensor Integration

### Magnetometer
Provides raw magnetic field data to calculate compass bearing. Uses low-pass filtering for smooth updates.

### Accelerometer
Detects device pitch and roll for:
- Digital bubble level visualization
- Surface calibration
- Orientation tracking

### Magnetic Declination
Converts magnetic bearing to true north using location-specific declination values (user-configurable in settings).

## App Architecture

The app follows a **Provider-based state management** pattern:

1. **CompassProvider**: Manages all sensor data and compass calculations
2. **Models**: Data structures (Waypoint) for persistence
3. **Widgets**: Reusable UI components (CompassDial, BubbleLevel)
4. **Screens**: Full-page views managing app navigation

## Development Roadmap

- [x] Core compass dial UI
- [x] Magnetometer integration
- [x] Accelerometer integration
- [x] Digital bubble level
- [ ] GPS integration
- [ ] Waypoint manager UI
- [ ] Waypoint persistence
- [ ] Location-based magnetic declination lookup
- [ ] Calibration wizard
- [ ] Data export (CSV)
- [ ] Dark mode optimization

## Permissions Required

**Android**:
- `INTERNET`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `BODY_SENSORS`

**iOS**:
- Location (When In Use)
- Motion & Fitness

## Contributing

This is a personal project. For contributions or issues, feel free to open a PR or issue.

## License

MIT License - See LICENSE file for details

---

## 📱 APK Build & Deployment

### Where to Find the APK

After building, the APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

**File Details**:
- Size: ~24 MB
- Status: Production Ready ✅
- Compatible with: Android 5.0 (API 21) and above
- Signed: Yes (Release signed)

### How to Use the APK

1. **Install on Device**:
   ```bash
   flutter install --release
   # OR manually transfer APK and install
   ```

2. **Share with Others**:
   - Email, WhatsApp, Telegram, Google Drive
   - Anyone with an Android device can install it

3. **Publish to Play Store**:
   - Upload to [Google Play Console](https://play.google.com/console)
   - App goes live in 24-48 hours

### Build Times

| Stage | First Build | Next Builds |
|-------|------------|------------|
| SDK Download | 5-10 min | - |
| Configuration | 2-3 min | - |
| Compilation | 10-15 min | 8-10 min |
| Build & Sign | 3-5 min | 3-5 min |
| **Total** | **40-60 min** | **15 min** |

Built with ❤️ for precision construction surveying.
