import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/track_model.dart';
import '../utils/geo_utils.dart';

class TrackService {
  static const String trackBoxName = 'tracks';
  late Box<Track> _trackBox;
  bool _isRecording = false;
  String? _activeTrackId;
  final List<TrackPoint> _currentPoints = [];
  double _currentDistance = 0.0;
  Timer? _recordTimer;

  bool get isRecording => _isRecording;
  String? get activeTrackId => _activeTrackId;
  List<TrackPoint> get currentPoints => _currentPoints;
  double get currentDistance => _currentDistance;

  bool get isInitialized => Hive.isBoxOpen(trackBoxName);

  Future<void> initialize() async {
    if (!isInitialized) {
      _trackBox = await Hive.openBox<Track>(trackBoxName);
    } else {
      _trackBox = Hive.box<Track>(trackBoxName);
    }
  }

  Future<Track> startRecording({
    required String name,
    String projectId = 'default',
    String color = '#00BCD4',
  }) async {
    final track = Track(
      id: const Uuid().v4(),
      name: name,
      projectId: projectId,
      startTime: DateTime.now(),
      points: [],
      color: color,
    );
    await _trackBox.put(track.id, track);
    _activeTrackId = track.id;
    _currentPoints.clear();
    _currentDistance = 0.0;
    _isRecording = true;
    return track;
  }

  void addPoint(TrackPoint point) {
    if (!_isRecording || _activeTrackId == null) return;
    
    if (_currentPoints.isNotEmpty) {
      final last = _currentPoints.last;
      final dist = GeoUtils.calculateDistance(
        last.latitude, last.longitude,
        point.latitude, point.longitude,
      );
      if (dist > 0.5 && dist < 500) {
        _currentDistance += dist;
      }
    }
    _currentPoints.add(point);
  }

  Future<Track?> stopRecording() async {
    if (!_isRecording || _activeTrackId == null) return null;
    
    _isRecording = false;
    final existingTrack = _trackBox.get(_activeTrackId);
    if (existingTrack == null) return null;

    final updatedTrack = existingTrack.copyWith(
      endTime: DateTime.now(),
      points: List.from(_currentPoints),
      totalDistance: _currentDistance,
    );
    await _trackBox.put(_activeTrackId!, updatedTrack);
    
    final track = updatedTrack;
    _activeTrackId = null;
    _currentPoints.clear();
    _currentDistance = 0.0;
    return track;
  }

  Future<List<Track>> getAllTracks() async {
    return _trackBox.values.toList();
  }

  Future<List<Track>> getTracksByProject(String projectId) async {
    return _trackBox.values.where((t) => t.projectId == projectId).toList();
  }

  Future<List<Track>> getTracksSortedByDate({bool descending = true}) async {
    final tracks = _trackBox.values.toList();
    tracks.sort((a, b) {
      if (descending) return b.startTime.compareTo(a.startTime);
      return a.startTime.compareTo(b.startTime);
    });
    return tracks;
  }

  Future<Track?> getTrack(String id) async {
    return _trackBox.get(id);
  }

  Future<void> deleteTrack(String id) async {
    await _trackBox.delete(id);
  }

  Future<void> updateTrack(String id, Track track) async {
    await _trackBox.put(id, track);
  }

  Future<int> getTrackCount() async {
    return _trackBox.length;
  }

  Future<void> deleteAllTracks() async {
    await _trackBox.clear();
  }

  Future<void> close() async {
    await _trackBox.close();
  }
}
