import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
  static const double _alphaFilter = 0.12; // low-pass smoothing
  static const int _minIntervalMs = 80; // throttle sensor updates
  static const double _minBearingDelta = 0.2; // degrees to notify
  static const double _minOrientationDelta = 0.5; // degrees to notify

  List<double> _lastMagnetometer = [0.0, 0.0, 0.0];
  List<double> _lastAccelerometer = [0.0, 0.0, 0.0];

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
        _lastMagnetometer = [event.x, event.y, event.z];
        _updateBearing();
      }, onError: (e) {
        // ignore sensor errors — app continues running
      });

      _accSub = accelerometerEvents.listen((AccelerometerEvent event) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastAccUpdateMs < _minIntervalMs) return;
        _lastAccUpdateMs = now;

        if (event.x.isNaN || event.y.isNaN || event.z.isNaN) return;
        _lastAccelerometer = [event.x, event.y, event.z];
        _updateOrientation();
      }, onError: (e) {
        // ignore
      });
    } catch (e) {
      // Sensors not available (e.g., desktop) — keep defaults
    }
  }

  void _updateBearing() {
    final x = _lastMagnetometer[0];
    final y = _lastMagnetometer[1];

    // Measured angle in degrees [0..360)
    double measured = atan2(y, x) * 180 / pi;
    measured = (measured + 360) % 360;

    // Compute shortest angle delta accounting for wrap-around
    double delta = ((measured - _bearing + 540) % 360) - 180;
    double newBearing = (_bearing + delta * _alphaFilter) % 360;
    if (newBearing < 0) newBearing += 360;

    // Only notify when change exceeds threshold to avoid jitter
    if (delta.abs() >= _minBearingDelta) {
      _bearing = newBearing;
      _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
      notifyListeners();
    } else {
      // keep smoothed value but do not re-render frequently
      _bearing = newBearing;
    }
  }

  void _updateOrientation() {
    final x = _lastAccelerometer[0];
    final y = _lastAccelerometer[1];
    final z = _lastAccelerometer[2];

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

  void setMagneticDeclination(double declination) {
    _magneticDeclination = declination;
    // Recompute true bearing immediately
    _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
    notifyListeners();
  }

  void updateGpsData({required double speed, required double accuracy, required bool hasLock}) {
    _speed = speed;
    _accuracy = accuracy;
    _hasGpsLock = hasLock;
    // No notifyListeners here as this is called frequently from GPS updates
  }

  void startCalibration() {
    _isCalibrating = true;
    // Reset calibration state
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
