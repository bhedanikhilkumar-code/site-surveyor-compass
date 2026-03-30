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
  // We filter raw sensors first for stability, then the heading for smoothness.
  static const double _sensorAlpha = 0.15; // Slightly less smoothing for responsiveness
  static const double _bearingAlpha = 0.2; // Faster bearing updates
  static const int _minIntervalMs = 50; // ~20 FPS updates (less jank than 33 FPS)

  v.Vector3 _accelFiltered = v.Vector3.zero();
  v.Vector3 _magFiltered = v.Vector3.zero();
  
  // For basic auto-calibration (Hard-iron offset removal)
  v.Vector3 _magMin = v.Vector3.all(double.infinity);
  v.Vector3 _magMax = v.Vector3.all(double.negativeInfinity);
  v.Vector3 _magOffset = v.Vector3.zero();

  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<AccelerometerEvent>? _accSub;

  int _lastUpdateMs = 0;

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
      _accSub = accelerometerEvents.listen((AccelerometerEvent event) {
        if (event.x.isNaN) return;
        // Low-pass filter raw accelerometer
        _accelFiltered.x = _accelFiltered.x + _sensorAlpha * (event.x - _accelFiltered.x);
        _accelFiltered.y = _accelFiltered.y + _sensorAlpha * (event.y - _accelFiltered.y);
        _accelFiltered.z = _accelFiltered.z + _sensorAlpha * (event.z - _accelFiltered.z);
        _updateCalculations();
      });

      _magSub = magnetometerEvents.listen((MagnetometerEvent event) {
        if (event.x.isNaN) return;
        
        // 1. Basic Auto-Calibration: track min/max to find center offset
        _updateMagOffsets(event.x, event.y, event.z);
        
        // 2. Apply offset (center the magnetic field)
        double cx = event.x - _magOffset.x;
        double cy = event.y - _magOffset.y;
        double cz = event.z - _magOffset.z;

        // 3. Low-pass filter the centered magnetometer data
        _magFiltered.x = _magFiltered.x + _sensorAlpha * (cx - _magFiltered.x);
        _magFiltered.y = _magFiltered.y + _sensorAlpha * (cy - _magFiltered.y);
        _magFiltered.z = _magFiltered.z + _sensorAlpha * (cz - _magFiltered.z);
        
        _updateCalculations();
      });
    } catch (e) {
      debugPrint("Compass sensors error: $e");
    }
  }

  void _updateMagOffsets(double x, double y, double z) {
    // We update the min/max range of the magnetic field observed
    _magMin.x = min(_magMin.x, x); _magMax.x = max(_magMax.x, x);
    _magMin.y = min(_magMin.y, y); _magMax.y = max(_magMax.y, y);
    _magMin.z = min(_magMin.z, z); _magMax.z = max(_magMax.z, z);
    
    // Offset is the center of the sphere
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

    _calculateOrientation();
    _calculateHeading();
    notifyListeners();
  }

  void _calculateOrientation() {
    final x = _accelFiltered.x;
    final y = _accelFiltered.y;
    final z = _accelFiltered.z;

    // Pitch & Roll for the bubble level
    _pitch = atan2(y, sqrt(x * x + z * z)) * 180 / pi;
    _roll = atan2(x, sqrt(y * y + z * z)) * 180 / pi;
  }

  void _calculateHeading() {
    if (_accelFiltered.length == 0 || _magFiltered.length == 0) return;

    // 1. Get Earth's coordinate system vectors projected onto device
    // East = Mag x Accel
    v.Vector3 east = _magFiltered.cross(_accelFiltered);
    if (east.length == 0) return;
    east.normalize();

    // North = Accel x East
    v.Vector3 north = _accelFiltered.cross(east);
    if (north.length == 0) return;
    north.normalize();

    // 2. Heading is the angle between device's Y-axis (top) and North vector
    // Standard formula: atan2(Y . East, Y . North)
    // Since Y = (0, 1, 0), this is just (east.y, north.y)
    double headingRad = atan2(east.y, north.y);
    double measured = (headingRad * 180 / pi + 360) % 360;

    // 3. Final smoothing of the bearing
    double delta = ((measured - _bearing + 540) % 360) - 180;
    _bearing = (_bearing + delta * _bearingAlpha) % 360;
    if (_bearing < 0) _bearing += 360;
    
    _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
  }

  // Cache GeoMag to avoid recreating on every GPS update
  GeoMag? _geoMag;
  double _lastDeclLat = 0;
  double _lastDeclLon = 0;

  void updateLocation(double lat, double lon, double alt) {
    try {
      // Only recalculate if moved more than ~10km from last calc point
      final latDelta = (lat - _lastDeclLat).abs();
      final lonDelta = (lon - _lastDeclLon).abs();
      if (_geoMag != null && latDelta < 0.1 && lonDelta < 0.1) return;
      
      _geoMag ??= GeoMag();
      final result = _geoMag!.calculate(lat, lon, alt * 3.28084, DateTime.now());
      _magneticDeclination = result.dec;
      _trueBearing = (_bearing + _magneticDeclination + 360) % 360;
      _lastDeclLat = lat;
      _lastDeclLon = lon;
      notifyListeners();
    } catch (e) {
      // ignore
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
  }

  void resetCalibration() {
    _magMin = v.Vector3.all(double.infinity);
    _magMax = v.Vector3.all(double.negativeInfinity);
    _magOffset = v.Vector3.zero();
    notifyListeners();
  }

  String getCardinalDirection(double bearing) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
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
