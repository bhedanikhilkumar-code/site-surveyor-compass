import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/track_model.dart';
import '../utils/geo_utils.dart';

class TrackService {
  static const String trackBoxName = 'tracks';
  late Box<Track> _trackBox;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _activeTrackId;
  final List<TrackPoint> _currentPoints = [];
  double _currentDistance = 0.0;
  Timer? _recordTimer;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
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
    _isPaused = false;
    return track;
  }

  void pauseRecording() {
    if (!_isRecording) return;
    _isPaused = true;
  }

  void resumeRecording() {
    if (!_isRecording || !_isPaused) return;
    _isPaused = false;
  }

  void addPoint(TrackPoint point) {
    if (!_isRecording || _isPaused || _activeTrackId == null) return;
    
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
    _isPaused = false;
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

  Future<String> exportToGpx(String trackId) async {
    final track = _trackBox.get(trackId);
    if (track == null) throw Exception('Track not found');

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="SiteSurveyorCompass"');
    buffer.writeln('     xmlns="http://www.topografix.com/GPX/1/1"');
    buffer.writeln('     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    buffer.writeln('     xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${_xmlEscape(track.name)}</name>');
    buffer.writeln('    <time>${track.startTime.toUtc().toIso8601String()}</time>');
    buffer.writeln('  </metadata>');

    for (final point in track.points) {
      buffer.writeln('  <wpt lat="${point.latitude}" lon="${point.longitude}">');
      if (point.altitude != 0) {
        buffer.writeln('    <ele>${point.altitude}</ele>');
      }
      buffer.writeln('    <time>${point.timestamp.toUtc().toIso8601String()}</time>');
      if (point.speed != null) {
        buffer.writeln('    <extensions><speed>${point.speed}</speed></extensions>');
      }
      buffer.writeln('  </wpt>');
    }

    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${_xmlEscape(track.name)}</name>');
    buffer.writeln('    <type>GPS Track</type>');
    buffer.writeln('    <trkseg>');

    for (final point in track.points) {
      buffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}">');
      if (point.altitude != 0) {
        buffer.writeln('        <ele>${point.altitude}</ele>');
      }
      buffer.writeln('        <time>${point.timestamp.toUtc().toIso8601String()}</time>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return await _writeToFile('${track.name}.gpx', buffer.toString());
  }

  Future<String> exportToKml(String trackId) async {
    final track = _trackBox.get(trackId);
    if (track == null) throw Exception('Track not found');

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>${_xmlEscape(track.name)}</name>');
    buffer.writeln('    <description>Track exported from SiteSurveyorCompass</description>');
    buffer.writeln('    <Style id="trackStyle">');
    buffer.writeln('      <LineStyle>');
    buffer.writeln('        <color>ff00bcd4</color>');
    buffer.writeln('        <width>4</width>');
    buffer.writeln('      </LineStyle>');
    buffer.writeln('      <PolyStyle>');
    buffer.writeln('        <color>4000bcd4</color>');
    buffer.writeln('      </PolyStyle>');
    buffer.writeln('    </Style>');

    buffer.writeln('    <Placemark>');
    buffer.writeln('      <name>${_xmlEscape(track.name)}</name>');
    buffer.writeln('      <styleUrl>#trackStyle</styleUrl>');
    buffer.writeln('      <LineString>');
    buffer.writeln('        <extrude>1</extrude>');
    buffer.writeln('        <tessellate>1</tessellate>');
    buffer.writeln('        <altitudeMode>absolute</altitudeMode>');
    buffer.writeln('        <coordinates>');

    for (final point in track.points) {
      buffer.writeln('          ${point.longitude},${point.latitude},${point.altitude}');
    }

    buffer.writeln('        </coordinates>');
    buffer.writeln('      </LineString>');
    buffer.writeln('    </Placemark>');

    for (int i = 0; i < track.points.length; i++) {
      final point = track.points[i];
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>Point ${i + 1}</name>');
      buffer.writeln('      <Point>');
      buffer.writeln('        <coordinates>${point.longitude},${point.latitude},${point.altitude}</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }

    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');

    return await _writeToFile('${track.name}.kml', buffer.toString());
  }

  String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<String> _writeToFile(String filename, String content) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsString(content);
    return filePath;
  }

  Future<void> shareFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found');
    await Share.shareXFiles([XFile(filePath)]);
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
