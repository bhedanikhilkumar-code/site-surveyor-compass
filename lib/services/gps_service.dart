import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import '../providers/compass_provider.dart';

class GpsService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isListening = false;
  String? _locationError;
  String? _address;
  StreamSubscription<Position>? _positionStream;
  CompassProvider? _compassProvider;

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
  String? get address => _address;
  double? get speed => _currentPosition?.speed;

  void setCompassProvider(CompassProvider provider) {
    _compassProvider = provider;
  }

  // Throttle address resolution
  double _lastResolvedLat = 0;
  double _lastResolvedLng = 0;
  int _lastResolvedMs = 0;
  static const int _addressThrottleMs = 30000; // Resolve at most every 30 seconds
  static const double _addressMinDistance = 0.001; // ~100m

  Future<void> _resolveAddress(double lat, double lng) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final latDelta = (lat - _lastResolvedLat).abs();
    final lngDelta = (lng - _lastResolvedLng).abs();
    
    // Skip if resolved recently and hasn't moved far
    if (now - _lastResolvedMs < _addressThrottleMs &&
        latDelta < _addressMinDistance &&
        lngDelta < _addressMinDistance) {
      return;
    }
    
    _lastResolvedLat = lat;
    _lastResolvedLng = lng;
    _lastResolvedMs = now;
    
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _address = [
          if (place.locality != null) place.locality,
          if (place.administrativeArea != null) place.administrativeArea,
          if (place.country != null) place.country,
        ].where((s) => s?.isNotEmpty ?? false).join(', ');
      }
    } catch (e) {
      _address = null;
    }
  }

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

      // Reject very inaccurate single-shot results
      if (position.accuracy > 1000) {
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
          if (position.accuracy > 5000) return;

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

          // Update compass provider with GPS data
          if (_compassProvider != null) {
            final speedKmh = position.speed.isNaN ? 0.0 : position.speed * 3.6;
            _compassProvider!.updateGpsData(
              speed: speedKmh,
              accuracy: position.accuracy,
              hasLock: position.accuracy < 50,
            );
            if (!position.altitude.isNaN) {
              _compassProvider!.updateLocation(
                position.latitude,
                position.longitude,
                position.altitude,
              );
            }
          }

          // Resolve address (don't await to avoid blocking)
          _resolveAddress(position.latitude, position.longitude);

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
