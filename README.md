# Site Surveyor Compass

Flutter-based field utility app for surveying, navigation, measurement, waypoint management, and on-site data capture.

## Overview
Site Surveyor Compass is a feature-rich mobile application built for field work and site surveying scenarios. It combines compass tools, GPS utilities, waypoint handling, measurement workflows, offline mapping support, reporting tools, and project-level organization into a single Flutter app.

The project is aimed at users who need practical field utilities rather than a single-purpose compass app. It brings together navigation, measurement, export, and record-keeping workflows in one mobile experience.

## Highlights
- Compass and orientation utilities for field alignment
- GPS-powered waypoint, track, and location workflows
- Measurement tools for distance, area, height, slope, and bearing
- Offline-friendly mapping and location support
- Project management, exports, and reporting utilities
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
- Android device/emulator for testing

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

## Notable Dependencies
- `provider` for state management
- `hive` and `hive_flutter` for local persistence
- `firebase_auth`, `cloud_firestore`, `firebase_messaging` for cloud features
- `flutter_map` and `latlong2` for mapping workflows
- `pdf` and `printing` for report generation
- `excel` for spreadsheet exports
- `record`, `audioplayers`, and `speech_to_text` for audio-related features

## Why This Project Matters
This project stands out because it combines many practical field workflows in one app: navigation, measurement, capture, reporting, and project organization. It demonstrates mobile product thinking, Flutter app architecture, sensor integration, data persistence, mapping, and utility-focused UX design.

## Status
The repository appears to be an actively evolving field-tools application with a broad feature set and room for production hardening, platform polishing, and further testing.
