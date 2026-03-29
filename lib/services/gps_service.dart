import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class GpsService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isListening = false;
  String? _locationError;
  StreamSubscription<Position>? _positionStream;

  Position? get currentPosition => _currentPosition;
  bool get isListening => _isListening;
  String? get locationError => _locationError;
  double? get latitude => _currentPosition?.latitude;
  double? get longitude => _currentPosition?.longitude;
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
      
      _currentPosition = position;
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
      if (_isListening) return;

      final hasPermission = await requestLocationPermissions();
      if (!hasPermission) {
        _locationError = 'Location permission required';
        notifyListeners();
        return;
      }

      _isListening = true;
      _locationError = null;
      notifyListeners();

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
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
    if (_currentPosition == null) {
      return 'No location available';
    }
    return '${_currentPosition!.latitude.toStringAsFixed(6)}, '
           '${_currentPosition!.longitude.toStringAsFixed(6)}';
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
