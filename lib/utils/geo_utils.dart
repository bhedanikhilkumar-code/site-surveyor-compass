import 'dart:math';

class GeoUtils {
  static const double earthRadiusKm = 6371.0;

  /// Calculate distance between two points using Haversine formula.
  /// Returns distance in meters.
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c * 1000; // meters
  }

  /// Calculate initial bearing from point1 to point2.
  /// Returns bearing in degrees (0-360).
  static double calculateBearing(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);
    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Format distance for display.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Calculate sunrise time for given date and location.
  /// Returns a formatted string like "06:30".
  static String calculateSunrise(double latitude, double longitude, DateTime date) {
    final result = _calculateSunriseSunset(latitude, longitude, date, isSunrise: true);
    return _formatTime(result);
  }

  /// Calculate sunset time for given date and location.
  /// Returns a formatted string like "18:45".
  static String calculateSunset(double latitude, double longitude, DateTime date) {
    final result = _calculateSunriseSunset(latitude, longitude, date, isSunrise: false);
    return _formatTime(result);
  }

  /// Calculate sunrise/sunset using the NOAA algorithm.
  static DateTime _calculateSunriseSunset(
    double latitude, double longitude,
    DateTime date, {
    required bool isSunrise,
  }) {
    final dayOfYear = _dayOfYear(date);
    final latRad = _toRadians(latitude);

    // Calculate solar declination
    final declination = _toRadians(
      23.45 * sin(_toRadians((360 / 365) * (dayOfYear - 81))),
    );

    // Calculate equation of time
    final b = _toRadians((360 / 365) * (dayOfYear - 81));
    final equationOfTime =
        9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b);

    // Calculate hour angle
    final cosHourAngle =
        (-sin(_toRadians(-0.833)) - sin(latRad) * sin(declination)) /
            (cos(latRad) * cos(declination));

    // Clamp for polar regions
    if (cosHourAngle > 1 || cosHourAngle < -1) {
      // Sun never rises or sets - return midnight
      return DateTime(date.year, date.month, date.day);
    }

    final hourAngle = _toDegrees(acos(cosHourAngle));
    final hourAngleMinutes = hourAngle * 4;

    // Calculate solar noon in minutes from midnight UTC
    final solarNoonMinutes = 720 - 4 * longitude - equationOfTime;

    double targetMinutes;

    if (isSunrise) {
      targetMinutes = solarNoonMinutes - hourAngleMinutes;
    } else {
      targetMinutes = solarNoonMinutes + hourAngleMinutes;
    }

    // Convert UTC minutes to local DateTime
    final hours = (targetMinutes / 60).floor();
    final minutes = (targetMinutes % 60).round();
    final utcDateTime = DateTime.utc(date.year, date.month, date.day, hours, minutes);
    return utcDateTime.toLocal();
  }

  static int _dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays + 1;
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
  static double _toDegrees(double radians) => radians * 180 / pi;

  /// Get compass direction string from bearing.
  static String bearingToCompass(double bearing) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final index = ((bearing + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}
