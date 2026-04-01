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

  // SENSOR SMOOTHING
  static const double _sensorAlpha = 0.15;
  static const double _bearingAlpha = 0.2;
  static const int _minIntervalMs = 50;

  v.Vector3 _accelFiltered = v.Vector3.zero();
  v.Vector3 _magFiltered = v.Vector3.zero();

  // For basic auto-calibration (Hard-iron offset removal)
  v.Vector3 _magMin = v.Vector3.all(double.infinity);
  v.Vector3 _magMax = v.Vector3.all(double.negativeInfinity);
  v.Vector3 _magOffset = v.Vector3.zero();

  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<AccelerometerEvent>? _accSub;

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

          _updateCalculations();
        },
        onError: (error) {
          debugPrint("Magnetometer error: $error");
        },
      );
    } catch (e) {
      debugPrint("Compass sensors initialization error: $e");
    }
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

    final pitchDenom = sqrt(x * x + z * z);
    final rollDenom = sqrt(y * y + z * z);

    if (pitchDenom == 0 || rollDenom == 0) return;

    _pitch = atan2(y, pitchDenom) * 180 / pi;
    _roll = atan2(x, rollDenom) * 180 / pi;
  }

  void _calculateHeading() {
    if (_accelFiltered.length == 0 || _magFiltered.length == 0) return;

    v.Vector3 east = _magFiltered.cross(_accelFiltered);
    if (east.length == 0) return;
    east.normalize();

    v.Vector3 north = _accelFiltered.cross(east);
    if (north.length == 0) return;
    north.normalize();

    double headingRad = atan2(east.y, north.y);
    double measured = (headingRad * 180 / pi + 360) % 360;

    double delta = ((measured - _bearing + 540) % 360) - 180;
    _bearing = (_bearing + delta * _bearingAlpha) % 360;
    if (_bearing < 0) _bearing += 360;

    _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
  }

  GeoMag? _geoMag;
  double _lastDeclLat = 0;
  double _lastDeclLon = 0;

  void updateLocation(double lat, double lon, double alt) {
    try {
      if (lat.isNaN || lon.isNaN || alt.isNaN) return;

      final latDelta = (lat - _lastDeclLat).abs();
      final lonDelta = (lon - _lastDeclLon).abs();
      if (_geoMag != null && latDelta < 0.1 && lonDelta < 0.1) return;

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
    super.dispose();
  }
}
