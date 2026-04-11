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

  // OPTIMIZED: Kalman-like filter for coordinates with better parameters
  double? _smoothedLat;
  double? _smoothedLng;
  double? _smoothedAlt;
  double _latErrorEstimate = 2.0;
  double _lngErrorEstimate = 2.0;
  double _altErrorEstimate = 10.0;

  // Static constants for magic numbers
  static const double _processNoise = 0.000005;   // Reduced process noise for smoother tracking
  static const double _altProcessNoise = 0.05;    // Reduced altitude process noise
  static const double _metersPerDegreeLat = 111319.5; // Meters per degree latitude
  static const double _minMeasurementNoise = 0.1; // Minimum noise floor for Kalman filter
  static const double _maxCorrectionDegrees = 0.001; // Max 100m correction per update
  static const double _altitudeNoiseMultiplier = 1.5; // Altitude error estimate multiplier
  static const double _accuracyThreshold = 200.0; // Reject readings with accuracy > 200m
  static const double _speedThresholdMs = 50.0; // Reject impossible speeds > 50 m/s
  static const double _accuracyLockThreshold = 20.0; // GPS lock threshold for compass
  static const int _addressThrottleMs = 30000; // 30 seconds throttle for address resolution
  static const double _addressMinDistance = 0.001; // Minimum distance for address resolution
  static const double _defaultDistanceFilter = 2.0; // Default distance filter in meters
  static const double _notificationThresholdDegrees = 0.00001; // Minimum change to trigger notify
  static const double _notificationThresholdAccuracy = 0.1; // Minimum accuracy change to trigger notify

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

  // Track previous values for change detection
  double? _previousLat;
  double? _previousLng;
  double? _previousAccuracy;

  void setCompassProvider(CompassProvider provider) {
    _compassProvider = provider;
  }

  // Throttle address resolution
  double _lastResolvedLat = 0;
  double _lastResolvedLng = 0;
  int _lastResolvedMs = 0;

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
      // Notify listeners when address is updated
      notifyListeners();
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
        _latErrorEstimate = bestPosition.accuracy / _metersPerDegreeLat;
        _lngErrorEstimate = bestPosition.accuracy / (_metersPerDegreeLat * cos(bestPosition.latitude * pi / 180));
        _altErrorEstimate = bestPosition.accuracy * _altitudeNoiseMultiplier;
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
    int intervalMs = 1000,    // BALANCED: 1 second updates for battery efficiency
    int distanceFilterMeters = 2, // REASONABLE: 2m filter for good responsiveness
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
          if (position.accuracy > _accuracyThreshold) return; // Reject bad readings

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
              // If claimed speed is impossible for a person, reject
              if (speedMs > _speedThresholdMs) return;
            }
          }

          _currentPosition = position;

          // FIX: Better Kalman filter for latitude with improved parameters
          final latDegPerMeter = 1 / _metersPerDegreeLat; // Meters per degree latitude
          final measurementNoiseLat = pow(max(position.accuracy * latDegPerMeter, _minMeasurementNoise), 2); // Minimum noise floor
          if (_smoothedLat == null) {
            _smoothedLat = position.latitude;
            _latErrorEstimate = position.accuracy * latDegPerMeter;
          } else {
            _latErrorEstimate += _processNoise;
            final kalmanGain = _latErrorEstimate / (_latErrorEstimate + measurementNoiseLat);
            // Limit correction to prevent jumps
            final correction = kalmanGain * (position.latitude - _smoothedLat!);
            if (correction.abs() < _maxCorrectionDegrees) { // Max correction per update
              _smoothedLat = _smoothedLat! + correction;
            }
            _latErrorEstimate *= (1 - kalmanGain);
          }

          // FIX: Better Kalman filter for longitude with improved parameters
          final lngDegPerMeterLng = 1 / (_metersPerDegreeLat * cos(position.latitude * pi / 180));
          final measurementNoiseLngFinal = pow(max(position.accuracy * lngDegPerMeterLng, _minMeasurementNoise), 2); // Minimum noise floor
          if (_smoothedLng == null) {
            _smoothedLng = position.longitude;
            _lngErrorEstimate = position.accuracy * lngDegPerMeterLng;
          } else {
            _lngErrorEstimate += _processNoise;
            final kalmanGain = _lngErrorEstimate / (_lngErrorEstimate + measurementNoiseLngFinal);
            // Limit correction to prevent jumps
            final correction = kalmanGain * (position.longitude - _smoothedLng!);
            if (correction.abs() < _maxCorrectionDegrees) { // Max correction per update
              _smoothedLng = _smoothedLng! + correction;
            }
            _lngErrorEstimate *= (1 - kalmanGain);
          }

          // IMPROVED: Altitude smoothing
          if (!position.altitude.isNaN) {
            if (_smoothedAlt == null) {
              _smoothedAlt = position.altitude;
              _altErrorEstimate = position.accuracy * _altitudeNoiseMultiplier;
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
              hasLock: position.accuracy < _accuracyLockThreshold, // Tighter lock threshold
              heading: position.heading != -1 ? position.heading : null,
            );
            if (!position.altitude.isNaN) {
              _compassProvider!.updateLocation(
                _smoothedLat ?? position.latitude,
                _smoothedLng ?? position.longitude,
                _smoothedAlt ?? position.altitude,
              );
            }
          }

          // Resolve address asynchronously to not block GPS stream
          Future.microtask(() => _resolveAddress(position.latitude, position.longitude));

          // Only notify listeners if coordinates or accuracy have changed significantly
          final currentLat = _smoothedLat ?? position.latitude;
          final currentLng = _smoothedLng ?? position.longitude;
          final currentAccuracy = position.accuracy;

          bool shouldNotify = false;
          if (_previousLat == null || (_previousLat! - currentLat).abs() > _notificationThresholdDegrees) {
            _previousLat = currentLat;
            shouldNotify = true;
          }
          if (_previousLng == null || (_previousLng! - currentLng).abs() > _notificationThresholdDegrees) {
            _previousLng = currentLng;
            shouldNotify = true;
          }
          if (_previousAccuracy == null || (_previousAccuracy! - currentAccuracy).abs() > _notificationThresholdAccuracy) {
            _previousAccuracy = currentAccuracy;
            shouldNotify = true;
          }

          if (shouldNotify) {
            notifyListeners();
          }
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
