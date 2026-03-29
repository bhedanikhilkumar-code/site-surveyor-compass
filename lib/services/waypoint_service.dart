import 'package:hive_flutter/hive_flutter.dart';
import '../models/waypoint_model.dart';
import 'package:uuid/uuid.dart';

class WaypointService {
  static const String waypointBoxName = 'waypoints';
  late Box<Waypoint> _waypointBox;

  bool get isInitialized => Hive.isBoxOpen(waypointBoxName);

  Future<void> initialize() async {
    if (!isInitialized) {
      _waypointBox = await Hive.openBox<Waypoint>(waypointBoxName);
    } else {
      _waypointBox = Hive.box<Waypoint>(waypointBoxName);
    }
  }

  Future<void> addWaypoint(Waypoint waypoint) async {
    await _waypointBox.put(waypoint.id, waypoint);
  }

  Future<Waypoint?> getWaypoint(String id) async {
    return _waypointBox.get(id);
  }

  Future<List<Waypoint>> getAllWaypoints() async {
    return _waypointBox.values.toList();
  }

  Future<List<Waypoint>> getWaypointsSortedByDate({bool descending = true}) async {
    final waypoints = _waypointBox.values.toList();
    waypoints.sort((a, b) {
      if (descending) {
        return b.createdAt.compareTo(a.createdAt);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return waypoints;
  }

  Future<void> updateWaypoint(String id, Waypoint waypoint) async {
    final updatedWaypoint = Waypoint(
      id: waypoint.id,
      name: waypoint.name,
      bearing: waypoint.bearing,
      latitude: waypoint.latitude,
      longitude: waypoint.longitude,
      altitude: waypoint.altitude,
      notes: waypoint.notes,
      createdAt: waypoint.createdAt,
      updatedAt: DateTime.now(),
    );
    await _waypointBox.put(id, updatedWaypoint);
  }

  Future<void> deleteWaypoint(String id) async {
    await _waypointBox.delete(id);
  }

  Future<void> deleteAllWaypoints() async {
    await _waypointBox.clear();
  }

  Future<int> getWaypointCount() async {
    return _waypointBox.length;
  }

  Future<List<Waypoint>> searchWaypoints(String query) async {
    return _waypointBox.values
        .where((wp) =>
            wp.name.toLowerCase().contains(query.toLowerCase()) ||
            wp.notes.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  String generateId() {
    return const Uuid().v4();
  }

  Future<Waypoint> createWaypoint({
    required String name,
    required double bearing,
    required double latitude,
    required double longitude,
    required double altitude,
    String notes = '',
  }) async {
    final waypoint = Waypoint(
      id: generateId(),
      name: name,
      bearing: bearing,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await addWaypoint(waypoint);
    return waypoint;
  }

  Future<void> close() async {
    await _waypointBox.close();
  }
}
