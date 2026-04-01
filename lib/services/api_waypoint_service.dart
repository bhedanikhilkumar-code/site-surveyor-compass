import '../models/waypoint_model.dart';
import 'waypoint_service.dart';
import 'firebase_service.dart';

class ApiWaypointService {
  final WaypointService _localService;
  final FirebaseService _firebaseService;
  bool _isOnline = false;

  ApiWaypointService({
    required WaypointService localService,
    required FirebaseService firebaseService,
  })  : _localService = localService,
        _firebaseService = firebaseService;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    await _localService.initialize();
    await _firebaseService.initialize();
  }

  Future<void> syncWithBackend() async {
    try {
      final remoteWaypoints = await _firebaseService.getAllWaypoints();
      final localWaypoints = await _localService.getAllWaypoints();

      for (final remote in remoteWaypoints) {
        final localIndex = localWaypoints.indexWhere((l) => l.id == remote.id);
        if (localIndex == -1) {
          await _localService.addWaypoint(remote);
        } else {
          final local = localWaypoints[localIndex];
          if (remote.updatedAt != null &&
              local.updatedAt != null &&
              remote.updatedAt!.isAfter(local.updatedAt!)) {
            await _localService.updateWaypoint(remote.id, remote);
          }
        }
      }
      _isOnline = true;
    } catch (e) {
      _isOnline = false;
    }
  }

  Future<List<Waypoint>> getAllWaypoints() async {
    return _localService.getAllWaypoints();
  }

  Future<List<Waypoint>> getWaypointsSortedByDate({bool descending = true}) async {
    return _localService.getWaypointsSortedByDate(descending: descending);
  }

  Future<Waypoint?> getWaypoint(String id) async {
    return _localService.getWaypoint(id);
  }

  Future<Waypoint> createWaypoint({
    required String name,
    required double bearing,
    required double latitude,
    required double longitude,
    required double altitude,
    String notes = '',
  }) async {
    final waypoint = await _localService.createWaypoint(
      name: name,
      bearing: bearing,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      notes: notes,
    );

    try {
      await _firebaseService.addWaypoint(waypoint);
    } catch (e) {
      // Will sync later when online
    }
    return waypoint;
  }

  Future<void> updateWaypoint(String id, Waypoint waypoint) async {
    await _localService.updateWaypoint(id, waypoint);
    try {
      await _firebaseService.updateWaypoint(id, waypoint);
    } catch (e) {
      // Will sync later when online
    }
  }

  Future<void> deleteWaypoint(String id) async {
    await _localService.deleteWaypoint(id);
    try {
      await _firebaseService.deleteWaypoint(id);
    } catch (e) {
      // Will sync later when online
    }
  }

  Future<List<Waypoint>> searchWaypoints(String query) async {
    return _localService.searchWaypoints(query);
  }

  Future<void> pushAllToBackend() async {
    final waypoints = await _localService.getAllWaypoints();
    for (final wp in waypoints) {
      try {
        await _firebaseService.addWaypoint(wp);
      } catch (e) {
        // Continue with others
      }
    }
  }

  Future<void> close() async {
    await _localService.close();
  }
}
