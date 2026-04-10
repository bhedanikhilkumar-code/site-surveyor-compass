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

  /// Calculate the area of a polygon using the shoelace formula.
  /// Points should be in order (clockwise or counterclockwise).
  /// Returns area in square meters.
  /// Note: This assumes planar coordinates; for geographic coordinates,
  /// consider projecting to UTM or using geodesic calculations.
  static double calculatePolygonArea(List<Map<String, double>> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i]['lat']! * points[j]['lon']! - points[j]['lat']! * points[i]['lon']!;
    }
    return (area.abs() / 2) * 111319.5 * 111319.5 * cos(_toRadians(points[0]['lat']!)); // Approximate conversion to meters
  }

  /// Check if a point is inside a polygon using ray casting algorithm.
  /// Points should be in order (clockwise or counterclockwise).
  static bool isPointInsidePolygon(
    List<Map<String, double>> polygon,
    Map<String, double> point,
  ) {
    int intersections = 0;
    final numVertices = polygon.length;

    for (int i = 0, j = numVertices - 1; i < numVertices; j = i++) {
      final vertex1 = polygon[i];
      final vertex2 = polygon[j];

      if (((vertex1['lat']! > point['lat']!) != (vertex2['lat']! > point['lat']!)) &&
          (point['lon']! < (vertex2['lon']! - vertex1['lon']!) * (point['lat']! - vertex1['lat']!) / (vertex2['lat']! - vertex1['lat']!) + vertex1['lon']!)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }

  /// Calculate the perimeter of a polygon.
  /// Returns perimeter in meters.
  static double calculatePolygonPerimeter(List<Map<String, double>> points) {
    if (points.length < 3) return 0.0;

    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      perimeter += calculateDistance(
        points[i]['lat']!, points[i]['lon']!,
        points[j]['lat']!, points[j]['lon']!,
      );
    }
    return perimeter;
  }

  /// Calculate the centroid of a polygon.
  /// Returns a Map with 'lat' and 'lon' keys.
  static Map<String, double> calculatePolygonCentroid(List<Map<String, double>> points) {
    if (points.length < 3) return {'lat': 0.0, 'lon': 0.0};

    double area = 0.0;
    double cx = 0.0;
    double cy = 0.0;

    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      final cross = points[i]['lat']! * points[j]['lon']! - points[j]['lat']! * points[i]['lon']!;
      area += cross;
      cx += (points[i]['lat']! + points[j]['lat']!) * cross;
      cy += (points[i]['lon']! + points[j]['lon']!) * cross;
    }

    area /= 2;
    cx /= (6 * area);
    cy /= (6 * area);

    return {'lat': cx, 'lon': cy};
  }

  /// Calculate the midpoint between two geographic points.
  /// Returns a Map with 'lat' and 'lon' keys.
  /// Note: This is an approximate calculation for small distances.
  static Map<String, double> calculateMidpoint(
    Map<String, double> point1,
    Map<String, double> point2,
  ) {
    final lat1 = _toRadians(point1['lat']!);
    final lon1 = _toRadians(point1['lon']!);
    final lat2 = _toRadians(point2['lat']!);
    final lon2 = _toRadians(point2['lon']!);

    final dLon = lon2 - lon1;

    final bx = cos(lat2) * cos(dLon);
    final by = cos(lat2) * sin(dLon);

    final lat3 = atan2(sin(lat1) + sin(lat2), sqrt((cos(lat1) + bx) * (cos(lat1) + bx) + by * by));
    final lon3 = lon1 + atan2(by, cos(lat1) + bx);

    return {
      'lat': _toDegrees(lat3),
      'lon': _toDegrees(lon3),
    };
  }

  /// Calculate the area of a triangle given three points.
  /// Returns area in square meters.
  static double calculateTriangleArea(
    Map<String, double> point1,
    Map<String, double> point2,
    Map<String, double> point3,
  ) {
    // Using shoelace formula
    final area = 0.5 * ((point1['lat']! * (point2['lon']! - point3['lon']!)) +
        (point2['lat']! * (point3['lon']! - point1['lon']!)) +
        (point3['lat']! * (point1['lon']! - point2['lon']!))).abs();
    // Approximate conversion to meters (rough for small areas)
    return area * 111319.5 * 111319.5 * cos(_toRadians((point1['lat']! + point2['lat']! + point3['lat']!) / 3));
  }

  /// Calculate the intersection point of two lines defined by two points each.
  /// Returns the intersection point as Map<String, double> with 'lat' and 'lon', or null if parallel.
  static Map<String, double>? calculateLineIntersection(
    Map<String, double> line1Point1,
    Map<String, double> line1Point2,
    Map<String, double> line2Point1,
    Map<String, double> line2Point2,
  ) {
    final x1 = line1Point1['lon']!;
    final y1 = line1Point1['lat']!;
    final x2 = line1Point2['lon']!;
    final y2 = line1Point2['lat']!;
    final x3 = line2Point1['lon']!;
    final y3 = line2Point1['lat']!;
    final x4 = line2Point2['lon']!;
    final y4 = line2Point2['lat']!;

    final denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if (denom.abs() < 1e-9) return null; // Parallel or coincident

    final t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom;
    final u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom;

    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      final ix = x1 + t * (x2 - x1);
      final iy = y1 + t * (y2 - y1);
      return {'lat': iy, 'lon': ix};
    }
    return null; // Intersection not within line segments
  }

  /// Format a coordinate (latitude or longitude) to DMS (Degrees, Minutes, Seconds) string.
  static String formatCoordinateDMS(double coordinate, bool isLatitude) {
    final direction = isLatitude ? (coordinate >= 0 ? 'N' : 'S') : (coordinate >= 0 ? 'E' : 'W');
    final absCoord = coordinate.abs();

    final degrees = absCoord.floor();
    final minutesFloat = (absCoord - degrees) * 60;
    final minutes = minutesFloat.floor();
    final seconds = (minutesFloat - minutes) * 60;

    return '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toStringAsFixed(2).padLeft(5, '0')}"$direction';
  }

  /// Calculate the angle at a vertex between three points.
  /// Returns the angle in degrees at point2.
  static double calculateAngleAtVertex(
    Map<String, double> point1,
    Map<String, double> point2,
    Map<String, double> point3,
  ) {
    final bearing1 = calculateBearing(point2['lat']!, point2['lon']!, point1['lat']!, point1['lon']!);
    final bearing2 = calculateBearing(point2['lat']!, point2['lon']!, point3['lat']!, point3['lon']!);

    double angle = bearing2 - bearing1;
    if (angle < 0) angle += 360.0;

    return angle;
  }

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
