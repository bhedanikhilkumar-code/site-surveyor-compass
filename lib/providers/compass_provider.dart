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
  double _speed = 0.0; // GPS speed in m/s
  double _accuracy = 0.0; // GPS accuracy in meters
  bool _hasGpsLock = false;

  // Smoothing / stability parameters
  static const double _alphaFilter = 0.15; 
  static const int _minIntervalMs = 40; 
  static const double _minBearingDelta = 0.1; 
  static const double _minOrientationDelta = 0.2; 

  v.Vector3 _accel = v.Vector3.zero();
  v.Vector3 _mag = v.Vector3.zero();

  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<AccelerometerEvent>? _accSub;

  int _lastMagUpdateMs = 0;
  int _lastAccUpdateMs = 0;

  double get bearing => _bearing;
  double get trueBearing => _trueBearing;
  double get pitch => _pitch;
  double get roll => _roll;
  double get magneticDeclination => _magneticDeclination;
  bool get isCalibrating => _isCalibrating;
  double get speed => _speed;
  double get accuracy => _accuracy;
  bool get hasGpsLock => _hasGpsLock;

  CompassProvider() {
    _initializeSensors();
  }

  void _initializeSensors() {
    try {
      _magSub = magnetometerEvents.listen((MagnetometerEvent event) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastMagUpdateMs < _minIntervalMs) return;
        _lastMagUpdateMs = now;

        if (event.x.isNaN || event.y.isNaN || event.z.isNaN) return;
        _mag.setValues(event.x, event.y, event.z);
        _calculateTiltCompensatedHeading();
      }, onError: (e) {
        // ignore sensor errors
      });

      _accSub = accelerometerEvents.listen((AccelerometerEvent event) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastAccUpdateMs < _minIntervalMs) return;
        _lastAccUpdateMs = now;

        if (event.x.isNaN || event.y.isNaN || event.z.isNaN) return;
        _accel.setValues(event.x, event.y, event.z);
        _updateOrientation();
      }, onError: (e) {
        // ignore
      });
    } catch (e) {
      // Sensors not available
    }
  }

  /// THE CORE IMPROVEMENT: Tilt-compensated heading calculation
  /// Using Cross-Product method for robust results even when device is tilted.
  void _calculateTiltCompensatedHeading() {
    if (_accel.length == 0 || _mag.length == 0) return;

    // 1. East Vector = Magnetic field cross Gravity
    v.Vector3 east = _mag.cross(_accel);
    if (east.length == 0) return;
    east.normalize();

    // 2. North Vector = Gravity cross East
    v.Vector3 north = _accel.cross(east);
    if (north.length == 0) return;
    north.normalize();

    // 3. Device's "forward" is Y-axis (0, 1, 0) in local space.
    // We project it onto our horizontal (North/East) plane.
    double headingRad = atan2(east.y, north.y);
    double measured = (headingRad * 180 / pi + 360) % 360;

    // 4. Smooth the result using EMA (Exponential Moving Average)
    double delta = ((measured - _bearing + 540) % 360) - 180;
    double newBearing = (_bearing + delta * _alphaFilter) % 360;
    if (newBearing < 0) newBearing += 360;

    if (delta.abs() >= _minBearingDelta) {
      _bearing = newBearing;
      _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
      notifyListeners();
    } else {
      _bearing = newBearing;
    }
  }

  void _updateOrientation() {
    final x = _accel.x;
    final y = _accel.y;
    final z = _accel.z;

    // Standard pitch/roll from accelerometer
    final newPitch = atan2(y, sqrt(x * x + z * z)) * 180 / pi;
    final newRoll = atan2(x, sqrt(y * y + z * z)) * 180 / pi;

    if ((newPitch - _pitch).abs() >= _minOrientationDelta ||
        (newRoll - _roll).abs() >= _minOrientationDelta) {
      _pitch = newPitch;
      _roll = newRoll;
      notifyListeners();
    } else {
      _pitch = newPitch;
      _roll = newRoll;
    }
  }

  /// Automatically update magnetic declination based on GPS location
  void updateLocation(double lat, double lon, double alt) {
    try {
      final geoMag = GeoMag();
      // Calculate declination for current location and time
      final result = geoMag.calculate(lat, lon, alt * 3.28084, DateTime.now()); // altitude in feet
      _magneticDeclination = result.dec;
      _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
      notifyListeners();
    } catch (e) {
      // fallback if geomag fails
    }
  }

  void setMagneticDeclination(double declination) {
    _magneticDeclination = declination;
    _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
    notifyListeners();
  }

  void updateGpsData({required double speed, required double accuracy, required bool hasLock}) {
    _speed = speed;
    _accuracy = accuracy;
    _hasGpsLock = hasLock;
    // No notifyListeners here
  }

  void startCalibration() {
    _isCalibrating = true;
    _bearing = 0.0;
    _trueBearing = 0.0;
    notifyListeners();
  }

  void stopCalibration() {
    _isCalibrating = false;
    notifyListeners();
  }

  String getCardinalDirection(double bearing) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    int index = ((bearing + 11.25) / 22.5).toInt() % 16;
    return directions[index];
  }

  @override
  void dispose() {
    _magSub?.cancel();
    _accSub?.cancel();
    super.dispose();
  }
}
