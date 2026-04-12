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

  /// Calculate the coordinates of a point given a start point, bearing, and distance.
  /// Returns a Map with 'lat' and 'lon' keys.
  static Map<String, double> calculatePointFromBearingAndDistance(
    Map<String, double> startPoint,
    double bearing,
    double distance,
  ) {
    final lat1 = _toRadians(startPoint['lat']!);
    final lon1 = _toRadians(startPoint['lon']!);
    final bearingRad = _toRadians(bearing);

    // Earth's radius in meters
    const R = 6371000.0;

    final lat2 = asin(sin(lat1) * cos(distance / R) + cos(lat1) * sin(distance / R) * cos(bearingRad));
    final lon2 = lon1 + atan2(sin(bearingRad) * sin(distance / R) * cos(lat1), cos(distance / R) - sin(lat1) * sin(lat2));

    return {
      'lat': _toDegrees(lat2),
      'lon': _toDegrees(lon2),
    };
  }

  /// Calculate the perpendicular distance from a point to a line defined by two points.
  /// Returns the distance in meters.
  static double calculatePerpendicularDistanceToLine(
    Map<String, double> point,
    Map<String, double> linePoint1,
    Map<String, double> linePoint2,
  ) {
    final x0 = point['lon']!;
    final y0 = point['lat']!;
    final x1 = linePoint1['lon']!;
    final y1 = linePoint1['lat']!;
    final x2 = linePoint2['lon']!;
    final y2 = linePoint2['lat']!;

    final numerator = ((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1).abs();
    final denominator = sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1));

    if (denominator == 0) return 0.0; // Points are the same

    final distance = numerator / denominator;

    // Approximate meters conversion
    return distance * 111319.5 * cos(_toRadians(y0));
  }

  /// Calculate the area of a quadrilateral given four points.
  /// Points should be in order (clockwise or counterclockwise).
  /// Returns area in square meters.
  static double calculateQuadrilateralArea(
    Map<String, double> point1,
    Map<String, double> point2,
    Map<String, double> point3,
    Map<String, double> point4,
  ) {
    // Using shoelace formula for quadrilateral
    final points = [point1, point2, point3, point4, point1]; // Close the loop
    double area = 0.0;
    for (int i = 0; i < 4; i++) {
      area += points[i]['lat']! * points[i + 1]['lon']! - points[i + 1]['lat']! * points[i]['lon']!;
    }
    area = (area.abs() / 2);

    // Approximate conversion to meters
    final avgLat = (point1['lat']! + point2['lat']! + point3['lat']! + point4['lat']!) / 4;
    return area * 111319.5 * 111319.5 * cos(_toRadians(avgLat));
  }

  /// Generate a grid of points around a center point.
  /// Returns a list of Map<String, double> with 'lat' and 'lon'.
  static List<Map<String, double>> generateGridPoints(
    Map<String, double> center,
    int numPointsX,
    int numPointsY,
    double spacingMeters,
  ) {
    final List<Map<String, double>> points = [];
    final halfX = (numPointsX - 1) / 2;
    final halfY = (numPointsY - 1) / 2;

    for (int i = 0; i < numPointsX; i++) {
      for (int j = 0; j < numPointsY; j++) {
        final deltaX = (i - halfX) * spacingMeters;
        final deltaY = (j - halfY) * spacingMeters;

        // Approximate conversion to lat/lon (rough for small distances)
        final deltaLat = deltaY / 111319.5;
        final deltaLon = deltaX / (111319.5 * cos(_toRadians(center['lat']!)));

        points.add({
          'lat': center['lat']! + deltaLat,
          'lon': center['lon']! + deltaLon,
        });
      }
    }
    return points;
  }

  /// Parse a coordinate from DMS (Degrees, Minutes, Seconds) string to decimal degrees.
  /// Input format: "12°34'56\"N" or "12°34'56.7\"S"
  static double? parseCoordinateDMS(String dmsString) {
    try {
      final parts = dmsString.split(RegExp('[°\'"]'));
      if (parts.length != 4) return null;

      final degrees = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = double.parse(parts[2]);
      final direction = parts[3];

      double decimal = degrees + minutes / 60.0 + seconds / 3600.0;

      if (direction == 'S' || direction == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      return null;
    }
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

  /// Calculate the area of a circle given its radius.
  /// Returns area in square meters.
  static double calculateCircleArea(double radius) {
    return pi * radius * radius;
  }

  /// Calculate the circumference of a circle given its radius.
  /// Returns circumference in meters.
  static double calculateCircleCircumference(double radius) {
    return 2 * pi * radius;
  }

  /// Calculate the area of a circular sector given radius and angle in degrees.
  /// Returns area in square meters.
  static double calculateSectorArea(double radius, double angleDegrees) {
    final angleRadians = _toRadians(angleDegrees);
    return (angleRadians / (2 * pi)) * calculateCircleArea(radius);
  }

  /// Calculate the area of a circular segment given radius and angle in degrees.
  /// Returns area in square meters.
  static double calculateSegmentArea(double radius, double angleDegrees) {
    final angleRadians = _toRadians(angleDegrees);
    final sectorArea = calculateSectorArea(radius, angleDegrees);
    final triangleArea = (radius * radius * angleRadians) / 2;
    return sectorArea - triangleArea;
  }

  /// Calculate the area of a trapezoid given two parallel sides and height.
  /// Returns area in square meters.
  static double calculateTrapezoidArea(double parallelSide1, double parallelSide2, double height) {
    return ((parallelSide1 + parallelSide2) / 2) * height;
  }

  /// Calculate the area of a regular polygon given number of sides and side length.
  /// Returns area in square meters.
  static double calculateRegularPolygonArea(int numSides, double sideLength) {
    final perimeter = numSides * sideLength;
    final apothem = sideLength / (2 * tan(pi / numSides));
    return (perimeter * apothem) / 2;
  }

  /// Calculate the area of a parallelogram given base and height.
  /// Returns area in square meters.
  static double calculateParallelogramArea(double base, double height) {
    return base * height;
  }

  /// Calculate the area of a rhombus given two diagonals.
  /// Returns area in square meters.
  static double calculateRhombusArea(double diagonal1, double diagonal2) {
    return (diagonal1 * diagonal2) / 2;
  }

  /// Calculate the area of an ellipse given major and minor axes.
  /// Returns area in square meters.
  static double calculateEllipseArea(double majorAxis, double minorAxis) {
    return pi * majorAxis * minorAxis;
  }

  /// Calculate the area of an annulus (ring) given outer and inner radii.
  /// Returns area in square meters.
  static double calculateAnnulusArea(double outerRadius, double innerRadius) {
    return pi * (outerRadius * outerRadius - innerRadius * innerRadius);
  }

  /// Calculate the area of a spherical cap given radius and height.
  /// Returns area in square meters.
  static double calculateSphericalCapArea(double radius, double height) {
    return 2 * pi * radius * height;
  }

  /// Calculate the slope percentage between two points with elevations.
  /// Returns slope as a percentage (positive for uphill, negative for downhill).
  static double calculateSlope(double elevation1, double elevation2, double distance) {
    if (distance <= 0) return 0.0;
    return ((elevation2 - elevation1) / distance) * 100.0;
  }



  /// Get UTM zone information for given latitude and longitude.
  /// Returns a Map with 'zoneNumber' (int) and 'zoneLetter' (String).
  static Map<String, dynamic> getUTMZone(double latitude, double longitude) {
    // Calculate zone number
    int zoneNumber = ((longitude + 180) / 6).floor() + 1;

    // Special cases for Norway and Svalbard
    if (latitude >= 56.0 && latitude < 64.0 && longitude >= 3.0 && longitude < 12.0) {
      zoneNumber = 32;
    }
    if (latitude >= 72.0 && latitude < 84.0) {
      if (longitude >= 0.0 && longitude < 9.0) {
        zoneNumber = 31;
      } else if (longitude >= 9.0 && longitude < 21.0) {
        zoneNumber = 33;
      } else if (longitude >= 21.0 && longitude < 33.0) {
        zoneNumber = 35;
      } else if (longitude >= 33.0 && longitude < 42.0) {
        zoneNumber = 37;
      }
    }

    // Calculate zone letter
    String zoneLetter;
    if (latitude >= -80.0 && latitude < -72.0) {
      zoneLetter = 'C';
    } else if (latitude >= -72.0 && latitude < -64.0) {
      zoneLetter = 'D';
    } else if (latitude >= -64.0 && latitude < -56.0) {
      zoneLetter = 'E';
    } else if (latitude >= -56.0 && latitude < -48.0) {
      zoneLetter = 'F';
    } else if (latitude >= -48.0 && latitude < -40.0) {
      zoneLetter = 'G';
    } else if (latitude >= -40.0 && latitude < -32.0) {
      zoneLetter = 'H';
    } else if (latitude >= -32.0 && latitude < -24.0) {
      zoneLetter = 'J';
    } else if (latitude >= -24.0 && latitude < -16.0) {
      zoneLetter = 'K';
    } else if (latitude >= -16.0 && latitude < -8.0) {
      zoneLetter = 'L';
    } else if (latitude >= -8.0 && latitude < 0.0) {
      zoneLetter = 'M';
    } else if (latitude >= 0.0 && latitude < 8.0) {
      zoneLetter = 'N';
    } else if (latitude >= 8.0 && latitude < 16.0) {
      zoneLetter = 'P';
    } else if (latitude >= 16.0 && latitude < 24.0) {
      zoneLetter = 'Q';
    } else if (latitude >= 24.0 && latitude < 32.0) {
      zoneLetter = 'R';
    } else if (latitude >= 32.0 && latitude < 40.0) {
      zoneLetter = 'S';
    } else if (latitude >= 40.0 && latitude < 48.0) {
      zoneLetter = 'T';
    } else if (latitude >= 48.0 && latitude < 56.0) {
      zoneLetter = 'U';
    } else if (latitude >= 56.0 && latitude < 64.0) {
      zoneLetter = 'V';
    } else if (latitude >= 64.0 && latitude < 72.0) {
      zoneLetter = 'W';
    } else if (latitude >= 72.0 && latitude < 80.0) {
      zoneLetter = 'X';
    } else {
      zoneLetter = ''; // Invalid latitude
    }

    return {
      'zoneNumber': zoneNumber,
      'zoneLetter': zoneLetter,
    };
  }

  /// Calculate the bounding box for a list of geographic points.
  /// Returns a Map with 'minLat', 'maxLat', 'minLon', 'maxLon'.
  static Map<String, double> calculateBoundingBox(List<Map<String, double>> points) {
    if (points.isEmpty) return {'minLat': 0.0, 'maxLat': 0.0, 'minLon': 0.0, 'maxLon': 0.0};

    double minLat = points[0]['lat']!;
    double maxLat = points[0]['lat']!;
    double minLon = points[0]['lon']!;
    double maxLon = points[0]['lon']!;

    for (final point in points) {
      if (point['lat']! < minLat) minLat = point['lat']!;
      if (point['lat']! > maxLat) maxLat = point['lat']!;
      if (point['lon']! < minLon) minLon = point['lon']!;
      if (point['lon']! > maxLon) maxLon = point['lon']!;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLon': minLon,
      'maxLon': maxLon,
    };
  }

  /// Process live data points for averaging or filtering.
  /// Returns a Map with 'avgLat' and 'avgLon'.
  static Map<String, double> processLiveData(List<Map<String, double>> liveData) {
    if (liveData.isEmpty) return {'avgLat': 0.0, 'avgLon': 0.0};

    double totalLat = 0.0;
    double totalLon = 0.0;

    for (final point in liveData) {
      totalLat += point['lat']!;
      totalLon += point['lon']!;
    }

    return {
      'avgLat': totalLat / liveData.length,
      'avgLon': totalLon / liveData.length,
    };
  }

  /// Perform deep research on geographic data by calculating statistical measures.
  /// Returns a Map with 'meanLat', 'meanLon', 'stdLat', 'stdLon'.
  static Map<String, double> deepResearch(List<Map<String, double>> data) {
    if (data.isEmpty) return {'meanLat': 0.0, 'meanLon': 0.0, 'stdLat': 0.0, 'stdLon': 0.0};

    double sumLat = 0.0;
    double sumLon = 0.0;
    for (final point in data) {
      sumLat += point['lat']!;
      sumLon += point['lon']!;
    }

    double meanLat = sumLat / data.length;
    double meanLon = sumLon / data.length;

    double sumSqLat = 0.0;
    double sumSqLon = 0.0;
    for (final point in data) {
      double diffLat = point['lat']! - meanLat;
      double diffLon = point['lon']! - meanLon;
      sumSqLat += diffLat * diffLat;
      sumSqLon += diffLon * diffLon;
    }

    double stdLat = sqrt(sumSqLat / data.length);
    double stdLon = sqrt(sumSqLon / data.length);

    return {
      'meanLat': meanLat,
      'meanLon': meanLon,
      'stdLat': stdLat,
      'stdLon': stdLon,
    };
  }

  /// Generate random geographic points within a bounding box.
  /// Returns a List of Map<String, double> with 'lat' and 'lon'.
  static List<Map<String, double>> generateRandomPoints(
    double minLat, double maxLat,
    double minLon, double maxLon,
    int count,
  ) {
    final List<Map<String, double>> points = [];
    final random = Random();

    for (int i = 0; i < count; i++) {
      final lat = minLat + random.nextDouble() * (maxLat - minLat);
      final lon = minLon + random.nextDouble() * (maxLon - minLon);
      points.add({'lat': lat, 'lon': lon});
    }

    return points;
  }

  /// Shuffle a list of geographic points randomly.
  /// Returns a shuffled List of Map<String, double>.
  static List<Map<String, double>> shufflePoints(List<Map<String, double>> points) {
    final shuffled = List<Map<String, double>>.from(points);
    shuffled.shuffle();
    return shuffled;
  }

  /// Generate a random geographic point within a circle defined by center and radius.
  /// Returns a Map with 'lat' and 'lon'.
  static Map<String, double> generateRandomPointInCircle(
    Map<String, double> center,
    double radiusMeters,
  ) {
    final random = Random();
    final bearing = random.nextDouble() * 360.0;
    final distance = sqrt(random.nextDouble()) * radiusMeters; // Uniform in area
    return calculatePointFromBearingAndDistance(center, bearing, distance);
  }

  /// Generate a random bearing between 0 and 360 degrees.
  /// Returns a double representing the bearing in degrees.
  static double generateRandomBearing() {
    final random = Random();
    return random.nextDouble() * 360.0;
  }

  /// Generate a random distance between minMeters and maxMeters.
  /// Returns a double representing the distance in meters.
  static double generateRandomDistance(double minMeters, double maxMeters) {
    final random = Random();
    return minMeters + random.nextDouble() * (maxMeters - minMeters);
  }

  /// Generate a random latitude between -90 and 90 degrees.
  /// Returns a double representing the latitude in degrees.
  static double generateRandomLat() {
    final random = Random();
    return (random.nextDouble() - 0.5) * 180.0; // -90 to 90
  }

  /// Generate a random longitude between -180 and 180 degrees.
  /// Returns a double representing the longitude in degrees.
  static double generateRandomLon() {
    final random = Random();
    return (random.nextDouble() - 0.5) * 360.0; // -180 to 180
  }

  /// Generate a random geographic point.
  /// Returns a Map with 'lat' and 'lon'.
  static Map<String, double> generateRandomPoint() {
    final random = Random();
    final lat = (random.nextDouble() - 0.5) * 180.0; // -90 to 90
    final lon = (random.nextDouble() - 0.5) * 360.0; // -180 to 180
    return {'lat': lat, 'lon': lon};
  }

  /// Generate a random elevation between minElevation and maxElevation.
  /// Returns a double representing the elevation in meters.
  static double generateRandomElevation(double minElevation, double maxElevation) {
    final random = Random();
    return minElevation + random.nextDouble() * (maxElevation - minElevation);
  }

  /// Generate a random radius between minRadius and maxRadius meters.
  /// Returns a double representing the radius in meters.
  static double generateRandomRadius(double minRadius, double maxRadius) {
    final random = Random();
    return minRadius + random.nextDouble() * (maxRadius - minRadius);
  }

  /// Generate a random slope between minSlope and maxSlope degrees.
  /// Returns a double representing the slope in degrees.
  static double generateRandomSlope(double minSlope, double maxSlope) {
    final random = Random();
    return minSlope + random.nextDouble() * (maxSlope - minSlope);
  }

  /// Generate a random area between minArea and maxArea square meters.
  /// Returns a double representing the area in square meters.
  static double generateRandomArea(double minArea, double maxArea) {
    final random = Random();
    return minArea + random.nextDouble() * (maxArea - minArea);
  }
}
