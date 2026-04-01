import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/waypoint_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String waypointsCollection = 'waypoints';
  bool _initialized = false;

  CollectionReference<Waypoint> get _waypointsRef =>
      _firestore.collection(waypointsCollection).withConverter<Waypoint>(
            fromFirestore: (snapshot, options) {
              final data = snapshot.data();
              if (data == null) {
                throw FormatException('Null waypoint data in Firestore');
              }
              return Waypoint.fromJson(data);
            },
            toFirestore: (waypoint, options) => waypoint.toJson(),
          );

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _initialized = true;
    } catch (e) {
      debugPrint('FirebaseService init error: $e');
    }
  }

  Stream<List<Waypoint>> waypointsStream() {
    return _waypointsRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Waypoint>> getAllWaypoints() async {
    try {
      final snapshot = await _waypointsRef.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Firebase getAllWaypoints error: $e');
      return [];
    }
  }

  Future<Waypoint?> getWaypoint(String id) async {
    try {
      final doc = await _waypointsRef.doc(id).get();
      return doc.data();
    } catch (e) {
      debugPrint('Firebase getWaypoint error: $e');
      return null;
    }
  }

  Future<void> addWaypoint(Waypoint waypoint) async {
    await _waypointsRef.doc(waypoint.id).set(waypoint);
  }

  Future<void> updateWaypoint(String id, Waypoint waypoint) async {
    await _waypointsRef.doc(id).update(waypoint.toJson());
  }

  Future<void> deleteWaypoint(String id) async {
    await _waypointsRef.doc(id).delete();
  }

  Future<void> deleteAllWaypoints() async {
    try {
      final snapshot = await _waypointsRef.get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firebase deleteAllWaypoints error: $e');
    }
  }

  Future<int> getWaypointCount() async {
    try {
      final snapshot = await _waypointsRef.get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Waypoint>> searchWaypoints(String query) async {
    try {
      final lowercaseQuery = query.toLowerCase();
      final allWaypoints = await getAllWaypoints();
      return allWaypoints.where((wp) =>
          wp.name.toLowerCase().contains(lowercaseQuery) ||
          wp.notes.toLowerCase().contains(lowercaseQuery)).toList();
    } catch (e) {
      return [];
    }
  }
}
