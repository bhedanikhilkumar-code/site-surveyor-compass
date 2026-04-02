import 'dart:async';
import 'dart:math';
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

  // IMPROVED: Kalman-like filter for coordinates
  double? _smoothedLat;
  double? _smoothedLng;
  double? _smoothedAlt;
  double _latErrorEstimate = 1.0;
  double _lngErrorEstimate = 1.0;
  double _altErrorEstimate = 5.0;
  static const double _processNoise = 0.00001;   // Position process noise
  static const double _altProcessNoise = 0.1;    // Altitude process noise

  Position? get currentPosition => _currentPosition;
  bool get isListening => _isListening;
  String? get locationError => _locationError;
  double? get latitude => _smoothedLat ?? _currentPosition?.latitude;
  double? get longitude => _smoothedLng ?? _currentPosition?.longitude;
  double? get altitude => _smoothedAlt ?? _currentPosition?.altitude;
  double? get accuracy => _currentPosition?.accuracy;
  String? get address => _address;
  double? get speed => _currentPosition?.speed;

  // GPS quality assessment
  int _consecutiveGoodReads = 0;
  double _lastGoodLat = 0;
  double _lastGoodLng = 0;

  void setCompassProvider(CompassProvider provider) {
    _compassProvider = provider;
  }

  // Throttle address resolution
  double _lastResolvedLat = 0;
  double _lastResolvedLng = 0;
  int _lastResolvedMs = 0;
  static const int _addressThrottleMs = 30000;
  static const double _addressMinDistance = 0.001;

  Future<void> _resolveAddress(double lat, double lng) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final latDelta = (lat - _lastResolvedLat).abs();
    final lngDelta = (lng - _lastResolvedLng).abs();

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
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea,
          if (place.country != null && place.country!.isNotEmpty) place.country,
        ].join(', ');
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

      // IMPROVED: Get multiple readings and pick the best one
      Position? bestPosition;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: const Duration(seconds: 15),
          );
          if (!position.latitude.isNaN && !position.longitude.isNaN) {
            if (bestPosition == null || position.accuracy < bestPosition.accuracy) {
              bestPosition = position;
            }
          }
        } catch (_) {}
        if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
      }

      if (bestPosition == null) {
        final last = await Geolocator.getLastKnownPosition();
        bestPosition = last;
      }

      if (bestPosition != null) {
        _currentPosition = bestPosition;
        _smoothedLat = bestPosition.latitude;
        _smoothedLng = bestPosition.longitude;
        _smoothedAlt = bestPosition.altitude;
        _latErrorEstimate = bestPosition.accuracy / 111319.5;
        _lngErrorEstimate = bestPosition.accuracy / (111319.5 * cos(bestPosition.latitude * pi / 180));
        _altErrorEstimate = bestPosition.accuracy * 1.5;
        _lastGoodLat = bestPosition.latitude;
        _lastGoodLng = bestPosition.longitude;
        _consecutiveGoodReads = 1;
      }

      _locationError = null;
      notifyListeners();
    } catch (e) {
      _locationError = 'Failed to get location: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> startLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int intervalMs = 500,     // IMPROVED: was 1000ms - faster updates
    int distanceFilterMeters = 1, // IMPROVED: was 5m - more granular
  }) async {
    try {
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
          // IMPROVED: Better validation
          if (position.latitude.isNaN || position.longitude.isNaN) return;
          if (position.latitude.abs() > 90 || position.longitude.abs() > 180) return;
          if (position.accuracy > 200) return; // IMPROVED: was 5000 - reject bad readings

          // IMPROVED: Detect GPS jumps (sudden position changes > 100m when stationary)
          if (_smoothedLat != null && _smoothedLng != null && _currentPosition != null) {
            final distMoved = _haversineDistance(
              _smoothedLat!, _smoothedLng!,
              position.latitude, position.longitude,
            );
            final timeDelta = _currentPosition != null
                ? position.timestamp.difference(_currentPosition!.timestamp).inMilliseconds / 1000.0
                : 1.0;
            if (timeDelta > 0) {
              final speedMs = distMoved / timeDelta;
              // If claimed speed is impossible for a person (>50 m/s = 180 km/h), reject
              if (speedMs > 50) return;
            }
          }

          _currentPosition = position;

          // IMPROVED: Kalman-like filter for latitude (in degrees)
          final latDegPerMeter = 1 / 111319.5; // Approximate meters per degree latitude
          final measurementNoiseLat = pow(position.accuracy * latDegPerMeter, 2);
          if (_smoothedLat == null) {
            _smoothedLat = position.latitude;
            _latErrorEstimate = position.accuracy * latDegPerMeter;
          } else {
            _latErrorEstimate += _processNoise;
            final kalmanGain = _latErrorEstimate / (_latErrorEstimate + measurementNoiseLat);
            _smoothedLat = _smoothedLat! + kalmanGain * (position.latitude - _smoothedLat!);
            _latErrorEstimate *= (1 - kalmanGain);
          }

          // IMPROVED: Kalman-like filter for longitude (in degrees)
          final lngDegPerMeter = 1 / (111319.5 * cos(position.latitude * pi / 180));
          final measurementNoiseLng = pow(position.accuracy * lngDegPerMeter, 2);
          if (_smoothedLng == null) {
            _smoothedLng = position.longitude;
            _lngErrorEstimate = position.accuracy * lngDegPerMeter;
          } else {
            _lngErrorEstimate += _processNoise;
            final kalmanGain = _lngErrorEstimate / (_lngErrorEstimate + measurementNoiseLng);
            _smoothedLng = _smoothedLng! + kalmanGain * (position.longitude - _smoothedLng!);
            _lngErrorEstimate *= (1 - kalmanGain);
          }

          // IMPROVED: Altitude smoothing
          if (!position.altitude.isNaN) {
            if (_smoothedAlt == null) {
              _smoothedAlt = position.altitude;
              _altErrorEstimate = position.accuracy * 1.5;
            } else {
              final altNoise = position.accuracy * position.accuracy * 2.25;
              _altErrorEstimate += _altProcessNoise;
              final kalmanGain = _altErrorEstimate / (_altErrorEstimate + altNoise);
              _smoothedAlt = _smoothedAlt! + kalmanGain * (position.altitude - _smoothedAlt!);
              _altErrorEstimate *= (1 - kalmanGain);
            }
          }

          // Track consecutive good readings
          if (position.accuracy < 10) {
            _consecutiveGoodReads++;
            _lastGoodLat = position.latitude;
            _lastGoodLng = position.longitude;
          }

          _locationError = null;

          // Update compass provider with GPS data
          if (_compassProvider != null) {
            final speedKmh = position.speed.isNaN ? 0.0 : position.speed * 3.6;
            _compassProvider!.updateGpsData(
              speed: speedKmh,
              accuracy: position.accuracy,
              hasLock: position.accuracy < 20, // IMPROVED: was 50 - tighter lock
            );
            if (!position.altitude.isNaN) {
              _compassProvider!.updateLocation(
                _smoothedLat ?? position.latitude,
                _smoothedLng ?? position.longitude,
                _smoothedAlt ?? position.altitude,
              );
            }
          }

          // Resolve address
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

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
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
    final alt = _smoothedAlt ?? _currentPosition?.altitude;
    if (alt == null) return 'N/A';
    return '${alt.toStringAsFixed(1)} m';
  }

  String getAccuracyString() {
    if (_currentPosition == null) return 'N/A';
    return '±${_currentPosition!.accuracy.toStringAsFixed(1)} m';
  }

  int get goodReadCount => _consecutiveGoodReads;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
