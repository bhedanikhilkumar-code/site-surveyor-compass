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
  
  static const double _alphaFilter = 0.1;
  
  late List<double> _lastMagnetometer = [0, 0, 0];
  late List<double> _lastAccelerometer = [0, 0, 0];

  double get bearing => _bearing;
  double get trueBearing => _trueBearing;
  double get pitch => _pitch;
  double get roll => _roll;
  double get magneticDeclination => _magneticDeclination;
  bool get isCalibrating => _isCalibrating;

  CompassProvider() {
    _initializeSensors();
  }

  void _initializeSensors() {
    magnetometerEvents.listen((MagnetometerEvent event) {
      _lastMagnetometer = [event.x, event.y, event.z];
      _updateBearing();
    });

    accelerometerEvents.listen((AccelerometerEvent event) {
      _lastAccelerometer = [event.x, event.y, event.z];
      _updateOrientation();
    });
  }

  void _updateBearing() {
    double x = _lastMagnetometer[0];
    double y = _lastMagnetometer[1];

    double bearing = atan2(y, x) * 180 / pi;
    bearing = (bearing + 360) % 360;

    _bearing = _bearing * (1 - _alphaFilter) + bearing * _alphaFilter;
    _trueBearing = (_bearing + _magneticDeclination + 360) % 360;

    notifyListeners();
  }

  void _updateOrientation() {
    double x = _lastAccelerometer[0];
    double y = _lastAccelerometer[1];
    double z = _lastAccelerometer[2];

    _pitch = atan2(y, sqrt(x * x + z * z)) * 180 / pi;
    _roll = atan2(x, sqrt(y * y + z * z)) * 180 / pi;

    notifyListeners();
  }

  void setMagneticDeclination(double declination) {
    _magneticDeclination = declination;
    _updateBearing();
  }

  void startCalibration() {
    _isCalibrating = true;
    // Reset bearing to 0 for calibration
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
    super.dispose();
  }
}
