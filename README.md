# Site Surveyor Compass

<p align="left">
  <a href="https://github.com/bhedanikhilkumar-code/site-surveyor-compass"><img src="https://img.shields.io/badge/Repo-GitHub-111827?style=for-the-badge&logo=github&logoColor=white" alt="Repo" /></a>
  <img src="https://img.shields.io/badge/App-Flutter-0A66C2?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter App" />
  <img src="https://img.shields.io/badge/Platform-Mobile-111827?style=for-the-badge" alt="Mobile" />
</p>

Flutter-based field utility app for surveying, navigation, measurement, waypoint management, and on-site reporting.

## What This Project Solves
Field work usually depends on multiple disconnected tools for orientation, measurement, waypoint handling, project capture, and reporting.

Site Surveyor Compass brings those tasks together in one mobile app so on-site workflows can stay faster, cleaner, and more practical.

## Preview
<p align="center">
  <img src="https://raw.githubusercontent.com/bhedanikhilkumar-code/site-surveyor-compass/main/tmp/pdfs/site_surveyor_compass_repo_summary_page1.png" alt="Site Surveyor Compass preview" width="780" />
</p>

## Key Capabilities
- Compass and orientation tools for field alignment
- GPS-powered waypoint, route, and location workflows
- Measurement tools for distance, area, height, slope, and bearing
- Offline-friendly mapping support
- Project-level organization, exports, and reporting
- Media capture, QR tools, voice notes, and cloud-oriented workflows

## Tech Stack
- Flutter
- Dart
- Provider
- Hive / Hive Flutter
- Firebase Auth, Firestore, Firebase Messaging
- Flutter Map
- Geolocator / Geocoding / sensors_plus
- PDF, Excel, QR, image, and audio-related packages

## Main Feature Areas
### Navigation & Survey Utilities
- AR compass
- Digital level
- Bearing line tools
- Stakeout workflows
- Coordinate conversion
- COGO calculations
- Terrain and map-based field assistance

### Measurement Tools
- Distance measurement
- Area measurement
- Height measurement
- Slope calculator
- GPS signal and positioning utilities

### Waypoints & Tracking
- Waypoint manager
- Saved locations
- Track recording
- Route and navigation support
- Bluetooth GPS integration

### Field Data Capture
- Camera GPS tagging
- Voice notes
- QR scan / share tools
- PDF report generation
- Excel export
- Import / export workflows

### Project & Sync Features
- Project manager
- Cloud backup and data sync screens
- Offline maps
- Weather support
- Firebase-backed authentication and cloud services

## Project Structure
```text
site-surveyor-compass/
├── lib/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── assets/
├── android/
├── ios/
└── scripts/
```

## Getting Started
### Prerequisites
- Flutter SDK 3.x
- Dart SDK compatible with the project
- Android Studio or VS Code with Flutter tooling
- Android device / emulator for testing

### Setup
```bash
git clone https://github.com/bhedanikhilkumar-code/site-surveyor-compass.git
cd site-surveyor-compass
flutter pub get
flutter run
```

## Useful Commands
### Run the app
```bash
flutter run
```

### Analyze
```bash
flutter analyze
```

### Test
```bash
flutter test
```

## Why This Project Stands Out
This project combines many practical field workflows into one app: navigation, measurement, capture, reporting, and project organization. It demonstrates Flutter product thinking, sensor integration, data persistence, mapping support, and utility-focused UX design.

## Status
This repository is an actively evolving field-tools application with broad feature coverage and room for further production hardening, polishing, and testing.
