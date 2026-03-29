# Site Surveyor Compass: Copilot Instructions

## Project Overview

Site Surveyor Compass is a Flutter mobile application for construction site surveying and site planning. It provides real-time compass readings with magnetic bearing and true north indicators, a digital bubble level using accelerometer data, and a waypoint manager for saving survey points with GPS coordinates.

The app follows a **Provider-based state management architecture** with clear separation between UI (screens/widgets), business logic (providers), data models, and services.

## Build, Test & Development Commands

### Setup & Running
```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Run on a specific device
flutter run -d <device-id>

# Clean and rebuild
flutter clean && flutter pub get
```

### Building for Release
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios
```

### Analysis & Linting
```bash
# Check for lint errors and warnings
flutter analyze

# Fix some issues automatically
dart fix --apply

# Format code
dart format lib/
```

### Code Generation
```bash
# Generate Hive adapters and other code (uses build_runner)
flutter pub run build_runner build

# Watch mode for continuous generation
flutter pub run build_runner watch
```

## Architecture & Key Patterns

### Layered Structure
- **Screens** (`lib/screens/`): Full-page UI views managing navigation
- **Providers** (`lib/providers/`): State management using `ChangeNotifier`
- **Widgets** (`lib/widgets/`): Reusable UI components
- **Services** (`lib/services/`): Business logic and data access (sensor integration, Hive persistence)
- **Models** (`lib/models/`): Data classes annotated with `@HiveType` for serialization
- **Utils** (`lib/utils/`): Constants and utility functions

### State Management: Provider Pattern
- `CompassProvider`: Manages sensor streams (magnetometer, accelerometer), bearing calculations, and orientation state
- `GpsService`: Handles GPS location tracking
- `WaypointService`: Handles persistent Waypoint storage via Hive (not a ChangeNotifier—injected as a service provider)
- All providers initialized in `main.dart` using `MultiProvider`

### Data Persistence: Hive
- Models use `@HiveType` and `@HiveField` annotations (generates `.g.dart` files via `build_runner`)
- `WaypointService` manages a single Hive box (`waypoints`) after initialization in `main()`
- Generated adapters registered in `main()` before running the app

### Sensor Integration Patterns
- **Magnetometer**: Raw X, Y, Z values converted to bearing using `atan2(y, x)` → normalized to 0-360°
- **Accelerometer**: X, Y, Z values converted to pitch/roll using `atan2()` for bubble level display
- **Low-pass filtering**: Alpha filter constant (`_alphaFilter = 0.1`) smooths rapid sensor fluctuations
- All sensor listeners set up in provider constructors, not manually in widgets

## Key Conventions

### Naming & Structure
- **File names**: snake_case (e.g., `compass_dial.dart`, `waypoint_model.dart`)
- **Classes**: PascalCase (e.g., `CompassProvider`, `HomeScreen`)
- **Constants**: `_uppercase` for private constants (e.g., `_alphaFilter`)
- **Getters**: Public-facing properties (e.g., `bearing`, `trueBearing`)

### Hive Models
- All models stored in Hive must have `part 'file.g.dart'` at the top
- Use unique `typeId` values for each `@HiveType` (start from 0; Waypoint uses 0)
- Use `@HiveField(index)` annotations with unique indices per model
- Run `flutter pub run build_runner build` after adding/modifying models

### Bearing & Direction Calculations
- Bearing is 0-360°, where 0° = North, 90° = East, 180° = South, 270° = West
- True bearing = magnetic bearing + magnetic declination (adjusted for location)
- Cardinal directions use 16-point compass (N, NNE, NE, ENE, E, etc.) via `getCardinalDirection()`
- Angles in calculations are in radians; convert to degrees with `* 180 / pi`

### Service Initialization
- Async services initialized in `main()` before `runApp()` to ensure availability
- Services injected via providers in `MultiProvider` list
- Use `Provider<T>` for singleton services (not ChangeNotifier), `ChangeNotifierProvider` for state
- Check `WaypointService.isInitialized` if needed to verify Hive box is open

### Permission Handling
- GPS and sensor permissions required; `permission_handler` package integrated
- Request permissions when accessing location/sensor data for the first time
- Handle permission denial gracefully (show UI feedback, disable features)

### Math & Trigonometry
- Bearing calculation: `atan2(y, x)` gives angle in radians (-π to π)
- Always normalize to 0-360° range: `(angle + 360) % 360`
- Pitch/roll derived from accelerometer vectors using atan2 on component ratios
- All sensor values are in standard SI units (magnetic field in microtesla, acceleration in m/s²)

## Testing Notes

- No tests currently in the repository (test dir is empty)
- When adding tests, use `flutter_test` (already in dev_dependencies)
- Test sensor logic independently from UI using mocked sensor streams
- Use `MockProvider` or `ProviderContainer` from Riverpod-like patterns if migrating to that

## Linting Rules

The project has strict lint rules enforced via `analysis_options.yaml`:
- All public APIs must have documentation (`package_api_docs`)
- Prefer `const` constructors and immutable patterns
- Avoid nullable returns where possible (`avoid_returning_null`)
- Use `late` for private fields initialized in constructors
- Cascade invocations encouraged for multiple method calls
- Prefer single quotes for strings
- Avoid bare `catch` clauses (use `catch` with `on` type specification)

Run `flutter analyze` before committing to catch violations.

## Common Tasks

### Adding a New Sensor Feature
1. Listen to sensor stream in `CompassProvider._initializeSensors()`
2. Process raw data in a private update method
3. Expose calculated value via a getter
4. Call `notifyListeners()` to trigger UI rebuilds
5. Add to widgets that subscribe via `context.watch<CompassProvider>()`

### Creating a New Model for Hive Storage
1. Create class with `@HiveType(typeId: X)` and `@HiveField(index)` annotations
2. Add `part 'file.g.dart'` at top of file
3. Register adapter in `main()`: `Hive.registerAdapter(YourClassAdapter())`
4. Run `flutter pub run build_runner build`
5. Manage via service class (see `WaypointService` pattern)

### Extending Waypoint Manager
- `WaypointService` provides: CRUD, search, sorting, count, ID generation
- Add new filter/sort methods to service; don't query Hive directly from widgets
- Always update `updatedAt` timestamp when modifying waypoints

## Dependencies & Versions

Key packages (see `pubspec.yaml`):
- **provider**: ^6.0.0 — State management
- **sensors_plus**: ^1.4.0 — Magnetometer & accelerometer
- **geolocator**: ^9.0.0 — GPS location
- **hive** & **hive_flutter**: ^2.2.3 — Local database
- **permission_handler**: ^11.4.0 — Permission requests
- **flutter_lints**: ^3.0.0 — Lint rules (enforced)
- **build_runner** & **hive_generator**: ^2.0+ — Code generation

Update checks can be run with `flutter pub outdated`.

## Material 3 & Theming

The app uses Material 3 with system theme mode (respects device dark/light settings):
- Light theme: `ColorScheme.fromSeed(seedColor: Colors.blueAccent, brightness: Brightness.light)`
- Dark theme: Same seed with `brightness: Brightness.dark`
- New widgets should respect `Theme.of(context)` for colors and text styles
