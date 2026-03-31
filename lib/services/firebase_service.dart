import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waypoint_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String waypointsCollection = 'waypoints';

  CollectionReference<Waypoint> get _waypointsRef =>
      _firestore.collection(waypointsCollection).withConverter<Waypoint>(
            fromFirestore: (snapshot, options) =>
                Waypoint.fromJson(snapshot.data()!),
            toFirestore: (waypoint, options) => waypoint.toJson(),
          );

  Future<void> initialize() async {
    // Firebase already initialized via Firebase.initializeApp() in main.dart
  }

  Stream<List<Waypoint>> waypointsStream() {
    return _waypointsRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Waypoint>> getAllWaypoints() async {
    final snapshot = await _waypointsRef.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Waypoint?> getWaypoint(String id) async {
    final doc = await _waypointsRef.doc(id).get();
    return doc.data();
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
    final snapshot = await _waypointsRef.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<int> getWaypointCount() async {
    final snapshot = await _waypointsRef.get();
    return snapshot.size;
  }

  Future<List<Waypoint>> searchWaypoints(String query) async {
    final lowercaseQuery = query.toLowerCase();
    final allWaypoints = await getAllWaypoints();
    return allWaypoints.where((wp) =>
        wp.name.toLowerCase().contains(lowercaseQuery) ||
        wp.notes.toLowerCase().contains(lowercaseQuery)).toList();
  }
}
