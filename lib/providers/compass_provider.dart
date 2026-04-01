import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart' as v;
import 'package:geomag/geomag.dart';
import 'dart:math';

class CompassProvider extends ChangeNotifier {
  double _bearing = 0.0;
  double _trueBearing = 0.0;
  double _pitch = 0.0;
  double _roll = 0.0;
  double _magneticDeclination = 0.0;
  bool _isCalibrating = false;
  double _speed = 0.0;
  double _accuracy = 0.0;
  bool _hasGpsLock = false;
  bool _magneticDisturbance = false;
  double _magneticFieldStrength = 0.0;

  // IMPROVED: Better smoothing values for responsive yet stable compass
  static const double _sensorAlpha = 0.25;       // was 0.15 - more responsive
  static const double _bearingAlpha = 0.3;        // was 0.2 - less lag
  static const double _gyroAlpha = 0.98;          // Complementary filter weight
  static const int _minIntervalMs = 30;           // was 50ms - faster updates

  v.Vector3 _accelFiltered = v.Vector3.zero();
  v.Vector3 _magFiltered = v.Vector3.zero();

  // For advanced auto-calibration (Hard-iron + Soft-iron estimation)
  v.Vector3 _magMin = v.Vector3.all(double.infinity);
  v.Vector3 _magMax = v.Vector3.all(double.negativeInfinity);
  v.Vector3 _magOffset = v.Vector3.zero();

  // Magnetic field baseline for disturbance detection
  double _baselineFieldStrength = 0;
  int _calibrationSamples = 0;
  static const int _calibrationSampleTarget = 100;

  // Complementary filter state
  double _gyroHeading = 0;
  double _lastGyroTimestamp = 0;
  bool _gyroInitialized = false;

  // Kalman-like filter for bearing
  double _bearingEstimate = 0;
  double _bearingErrorEstimate = 1.0;
  static const double _bearingQ = 0.01;  // Process noise
  static const double _bearingR = 0.5;   // Measurement noise

  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  int _lastUpdateMs = 0;
  bool _disposed = false;

  double get bearing => _bearing;
  double get trueBearing => _trueBearing;
  double get pitch => _pitch;
  double get roll => _roll;
  double get magneticDeclination => _magneticDeclination;
  bool get isCalibrating => _isCalibrating;
  double get speed => _speed;
  double get accuracy => _accuracy;
  bool get hasGpsLock => _hasGpsLock;
  bool get magneticDisturbance => _magneticDisturbance;
  double get magneticFieldStrength => _magneticFieldStrength;
  int get calibrationProgress => ((_calibrationSamples / _calibrationSampleTarget) * 100).clamp(0, 100).toInt();

  CompassProvider() {
    _initializeSensors();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _initializeSensors() {
    try {
      _accSub = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          if (event.x.isNaN || event.y.isNaN || event.z.isNaN) return;
          _accelFiltered.x = _accelFiltered.x + _sensorAlpha * (event.x - _accelFiltered.x);
          _accelFiltered.y = _accelFiltered.y + _sensorAlpha * (event.y - _accelFiltered.y);
          _accelFiltered.z = _accelFiltered.z + _sensorAlpha * (event.z - _accelFiltered.z);
          _updateCalculations();
        },
        onError: (error) {
          debugPrint("Accelerometer error: $error");
        },
      );

      _magSub = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          if (event.x.isNaN || event.y.isNaN || event.z.isNaN) return;

          _updateMagOffsets(event.x, event.y, event.z);

          double cx = event.x - _magOffset.x;
          double cy = event.y - _magOffset.y;
          double cz = event.z - _magOffset.z;

          _magFiltered.x = _magFiltered.x + _sensorAlpha * (cx - _magFiltered.x);
          _magFiltered.y = _magFiltered.y + _sensorAlpha * (cy - _magFiltered.y);
          _magFiltered.z = _magFiltered.z + _sensorAlpha * (cz - _magFiltered.z);

          // Detect magnetic disturbance
          _magneticFieldStrength = sqrt(cx * cx + cy * cy + cz * cz);
          _detectMagneticDisturbance();

          _updateCalculations();
        },
        onError: (error) {
          debugPrint("Magnetometer error: $error");
        },
      );

      // ADDED: Gyroscope for complementary filter
      _gyroSub = gyroscopeEventStream().listen(
        (GyroscopeEvent event) {
          if (event.x.isNaN || event.y.isNaN || event.z.isNaN) return;

          final now = DateTime.now().microsecondsSinceEpoch / 1000000.0;
          if (_lastGyroTimestamp > 0) {
            final dt = now - _lastGyroTimestamp;
            if (dt > 0 && dt < 0.5) {
              // Integrate gyroscope z-axis for heading change
              _gyroHeading += event.z * dt * (180 / pi);
              _gyroHeading = ((_gyroHeading % 360) + 360) % 360;
              _gyroInitialized = true;
            }
          }
          _lastGyroTimestamp = now;
        },
        onError: (error) {
          debugPrint("Gyroscope error: $error");
        },
      );
    } catch (e) {
      debugPrint("Compass sensors initialization error: $e");
    }
  }

  void _detectMagneticDisturbance() {
    if (_baselineFieldStrength <= 0) return;

    // If field strength deviates more than 30% from baseline, flag disturbance
    final deviation = (_magneticFieldStrength - _baselineFieldStrength).abs() / _baselineFieldStrength;
    _magneticDisturbance = deviation > 0.3;
  }

  void _updateMagOffsets(double x, double y, double z) {
    if (x.isNaN || y.isNaN || z.isNaN) return;

    _magMin.x = min(_magMin.x, x);
    _magMax.x = max(_magMax.x, x);
    _magMin.y = min(_magMin.y, y);
    _magMax.y = max(_magMax.y, y);
    _magMin.z = min(_magMin.z, z);
    _magMax.z = max(_magMax.z, z);

    if (_magMin.x != double.infinity) {
      _magOffset.x = (_magMin.x + _magMax.x) / 2;
      _magOffset.y = (_magMin.y + _magMax.y) / 2;
      _magOffset.z = (_magMin.z + _magMax.z) / 2;

      // Build baseline during calibration
      _calibrationSamples++;
      if (_calibrationSamples <= _calibrationSampleTarget) {
        final currentStrength = sqrt(x * x + y * y + z * z);
        _baselineFieldStrength = (_baselineFieldStrength * (_calibrationSamples - 1) + currentStrength) / _calibrationSamples;
      }
    }
  }

  void _updateCalculations() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateMs < _minIntervalMs) return;
    _lastUpdateMs = now;

    try {
      _calculateOrientation();
      _calculateHeading();
      _safeNotifyListeners();
    } catch (e) {
      debugPrint("Compass calculation error: $e");
    }
  }

  void _calculateOrientation() {
    final x = _accelFiltered.x;
    final y = _accelFiltered.y;
    final z = _accelFiltered.z;

    // IMPROVED: More accurate pitch/roll using atan2
    _pitch = atan2(-y, sqrt(x * x + z * z)) * 180 / pi;
    _roll = atan2(x, sqrt(y * y + z * z)) * 180 / pi;
  }

  void _calculateHeading() {
    if (_accelFiltered.length == 0 || _magFiltered.length == 0) return;

    // Tilt-compensated magnetic heading
    v.Vector3 east = _magFiltered.cross(_accelFiltered);
    if (east.length == 0) return;
    east.normalize();

    v.Vector3 north = _accelFiltered.cross(east);
    if (north.length == 0) return;
    north.normalize();

    double magneticHeading = atan2(east.y, north.y) * 180 / pi;
    magneticHeading = (magneticHeading + 360) % 360;

    // IMPROVED: Complementary filter - fuse gyro + magnetometer
    double fusedHeading = magneticHeading;
    if (_gyroInitialized && !_magneticDisturbance) {
      // Use gyro when magnetic is stable, magnetometer corrects drift
      fusedHeading = _gyroAlpha * _gyroHeading + (1 - _gyroAlpha) * magneticHeading;
      fusedHeading = ((fusedHeading % 360) + 360) % 360;
      // Sync gyro to fused result to prevent drift
      _gyroHeading = fusedHeading;
    } else if (_magneticDisturbance) {
      // During disturbance, rely more on gyro
      fusedHeading = 0.95 * _gyroHeading + 0.05 * magneticHeading;
      fusedHeading = ((fusedHeading % 360) + 360) % 360;
      _gyroHeading = fusedHeading;
    }

    // IMPROVED: Kalman-like filter for smooth, accurate bearing
    double delta = ((fusedHeading - _bearingEstimate + 540) % 360) - 180;
    _bearingErrorEstimate += _bearingQ;
    final kalmanGain = _bearingErrorEstimate / (_bearingErrorEstimate + _bearingR);
    _bearingEstimate += kalmanGain * delta;
    _bearingEstimate = ((_bearingEstimate % 360) + 360) % 360;
    _bearingErrorEstimate *= (1 - kalmanGain);

    _bearing = _bearingEstimate;
    _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
  }

  GeoMag? _geoMag;
  double _lastDeclLat = 0;
  double _lastDeclLon = 0;

  void updateLocation(double lat, double lon, double alt) {
    try {
      if (lat.isNaN || lon.isNaN || alt.isNaN) return;

      // IMPROVED: Smaller threshold for more frequent declination updates (was 0.1° ~11km)
      final latDelta = (lat - _lastDeclLat).abs();
      final lonDelta = (lon - _lastDeclLon).abs();
      if (_geoMag != null && latDelta < 0.01 && lonDelta < 0.01) return; // ~1km threshold

      _geoMag ??= GeoMag();
      final result = _geoMag!.calculate(lat, lon, alt * 3.28084, DateTime.now());
      _magneticDeclination = result.dec;
      _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
      _lastDeclLat = lat;
      _lastDeclLon = lon;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint("GeoMag calculation error: $e");
    }
  }

  void setMagneticDeclination(double declination) {
    if (declination.isNaN) return;
    _magneticDeclination = declination;
    _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
    _safeNotifyListeners();
  }

  void updateGpsData({required double speed, required double accuracy, required bool hasLock}) {
    _speed = speed.isNaN ? 0.0 : speed;
    _accuracy = accuracy.isNaN ? 0.0 : accuracy;
    _hasGpsLock = hasLock;
  }

  void resetCalibration() {
    _magMin = v.Vector3.all(double.infinity);
    _magMax = v.Vector3.all(double.negativeInfinity);
    _magOffset = v.Vector3.zero();
    _baselineFieldStrength = 0;
    _calibrationSamples = 0;
    _magneticDisturbance = false;
    _safeNotifyListeners();
  }

  String getCardinalDirection(double bearing) {
    if (bearing.isNaN) return 'N';
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    int index = ((bearing + 11.25) / 22.5).toInt() % 16;
    return directions[index];
  }

  @override
  void dispose() {
    _disposed = true;
    _magSub?.cancel();
    _accSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }
}
