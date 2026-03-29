import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class GpsService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isListening = false;
  String? _locationError;
  StreamSubscription<Position>? _positionStream;

  // Small smoothing filter for displayed coordinates
  double? _smoothedLat;
  double? _smoothedLng;
  static const double _locAlpha = 0.6; // smoothing factor (0-1)

  Position? get currentPosition => _currentPosition;
  bool get isListening => _isListening;
  String? get locationError => _locationError;
  double? get latitude => _smoothedLat ?? _currentPosition?.latitude;
  double? get longitude => _smoothedLng ?? _currentPosition?.longitude;
  double? get altitude => _currentPosition?.altitude;
  double? get accuracy => _currentPosition?.accuracy;

  Future<bool> requestLocationPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      } else if (permission == LocationPermission.deniedForever) {
        _locationError = 'Location permission permanently denied. Enable in settings.';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _locationError = 'Error requesting permissions: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> getInitialPosition() async {
    try {
      _locationError = null;
      final hasPermission = await requestLocationPermissions();

      if (!hasPermission) {
        _locationError = 'Location permission denied';
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 30),
      );

      if (position == null) {
        _locationError = 'Unable to get initial position';
        notifyListeners();
        return;
      }

      // Reject very inaccurate single-shot results
      if (position.accuracy != null && position.accuracy > 1000) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          _currentPosition = last;
        } else {
          _currentPosition = position;
        }
      } else {
        _currentPosition = position;
      }

      // Initialize smoothed coords
      _smoothedLat = _currentPosition?.latitude;
      _smoothedLng = _currentPosition?.longitude;

      _locationError = null;
      notifyListeners();
    } catch (e) {
      _locationError = 'Failed to get location: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> startLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int intervalMs = 1000,
    int distanceFilterMeters = 5,
  }) async {
    try {
      // Cancel any existing stream to avoid duplicates
      await _positionStream?.cancel();

      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) {
        _locationError = 'Location permission required';
        notifyListeners();
        return;
      }

      _isListening = true;
      _locationError = null;
      notifyListeners();

      final LocationSettings locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          // Ignore implausible readings
          if (position.latitude.isNaN || position.longitude.isNaN) return;
          if (position.accuracy != null && position.accuracy > 5000) return;

          _currentPosition = position;

          // Smooth displayed coordinates to reduce jitter
          if (_smoothedLat == null || _smoothedLng == null) {
            _smoothedLat = position.latitude;
            _smoothedLng = position.longitude;
          } else {
            _smoothedLat = (_smoothedLat! * (1 - _locAlpha)) + (position.latitude * _locAlpha);
            _smoothedLng = (_smoothedLng! * (1 - _locAlpha)) + (position.longitude * _locAlpha);
          }

          _locationError = null;
          notifyListeners();
        },
        onError: (dynamic error) {
          _locationError = 'Location stream error: ${error.toString()}';
          _isListening = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _locationError = 'Failed to start location updates: ${e.toString()}';
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopLocationUpdates() async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _locationError = 'Error stopping location updates: ${e.toString()}';
      notifyListeners();
    }
  }

  String getLocationString() {
    final lat = _smoothedLat ?? _currentPosition?.latitude;
    final lng = _smoothedLng ?? _currentPosition?.longitude;
    if (lat == null || lng == null) return 'No location available';
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  String getAltitudeString() {
    if (_currentPosition == null) return 'N/A';
    return '${_currentPosition!.altitude.toStringAsFixed(1)} m';
  }

  String getAccuracyString() {
    if (_currentPosition == null) return 'N/A';
    return '±${_currentPosition!.accuracy.toStringAsFixed(1)} m';
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
