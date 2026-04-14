import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import '../lib/utils/geo_utils.dart';

void main() {
  group('GeoUtils Tests', () {
    test('calculateDistance returns correct distance', () {
      // Test distance between two known points
      final distance = GeoUtils.calculateDistance(0, 0, 0, 1);
      expect(distance, closeTo(111319, 1000)); // Approximate distance in meters
    });

    test('calculatePolygonArea returns correct area for triangle', () {
      final points = [
        {'lat': 0.0, 'lon': 0.0},
        {'lat': 1.0, 'lon': 0.0},
        {'lat': 0.0, 'lon': 1.0},
      ];
      final area = GeoUtils.calculatePolygonArea(points);
      expect(area, greaterThan(0));
    });

    test('generateRandomNumber returns value in range', () {
      final random = GeoUtils.generateRandomNumber(0, 10);
      expect(random, greaterThanOrEqualTo(0));
      expect(random, lessThanOrEqualTo(10));
    });

    test('generateRandomInt returns integer in range', () {
      final random = GeoUtils.generateRandomInt(0, 10);
      expect(random, isA<int>());
      expect(random, greaterThanOrEqualTo(0));
      expect(random, lessThanOrEqualTo(10));
    });

    test('generateRandomBool returns bool', () {
      final random = GeoUtils.generateRandomBool();
      expect(random, isA<bool>());
    });

    test('generateRandomString returns string of correct length', () {
      final random = GeoUtils.generateRandomString(5);
      expect(random, isA<String>());
      expect(random.length, 5);
    });

    test('generateRandomCoordinate returns valid coordinates', () {
      final coord = GeoUtils.generateRandomCoordinate();
      expect(coord, isA<Map<String, double>>());
      expect(coord['lat'], isA<double>());
      expect(coord['lon'], isA<double>());
    });

    test('generateRandomWaypoint returns waypoint with name and coords', () {
      final waypoint = GeoUtils.generateRandomWaypoint();
      expect(waypoint, isA<Map<String, dynamic>>());
      expect(waypoint['name'], isA<String>());
      expect(waypoint['lat'], isA<double>());
      expect(waypoint['lon'], isA<double>());
    });
  });
}