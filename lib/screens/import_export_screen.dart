import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/waypoint_model.dart';
import '../models/track_model.dart';
import '../services/api_waypoint_service.dart';
import '../services/track_service.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({Key? key}) : super(key: key);

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final TrackService _trackService = TrackService();
  List<Waypoint> _waypoints = [];
  List<Track> _tracks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final waypointService = context.read<ApiWaypointService>();
    await _trackService.initialize();
    final waypoints = await waypointService.getAllWaypoints();
    final tracks = await _trackService.getAllTracks();
    if (mounted) {
      setState(() {
        _waypoints = waypoints;
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportKml() async {
    if (_waypoints.isEmpty && _tracks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
      buffer.writeln('<Document>');
      buffer.writeln('<name>GeoCompass Pro Export - ${DateTime.now().toIso8601String()}</name>');
      buffer.writeln('<description>Exported from GeoCompass Pro Site Surveyor</description>');

      for (final wp in _waypoints) {
        buffer.writeln('<Placemark>');
        buffer.writeln('<name>${_xmlEscape(wp.name)}</name>');
        buffer.writeln('<description>${_xmlEscape(wp.notes)}</description>');
        buffer.writeln('<Point><coordinates>${wp.longitude},${wp.latitude},${wp.altitude}</coordinates></Point>');
        buffer.writeln('</Placemark>');
      }

      for (final track in _tracks) {
        if (track.points.isEmpty) continue;
        buffer.writeln('<Placemark>');
        buffer.writeln('<name>${_xmlEscape(track.name)}</name>');
        buffer.writeln('<LineString><coordinates>');
        for (final p in track.points) {
          buffer.writeln('${p.longitude},${p.latitude},${p.altitude}');
        }
        buffer.writeln('</coordinates></LineString>');
        buffer.writeln('</Placemark>');
      }

      buffer.writeln('</Document></kml>');

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/site_survey_export_$timestamp.kml');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'GeoCompass Pro - KML Export');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KML exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('KML export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportGpx() async {
    if (_waypoints.isEmpty && _tracks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<gpx version="1.1" creator="GeoCompass Pro" xmlns="http://www.topografix.com/GPX/1/1">');
      buffer.writeln('<metadata><name>GeoCompass Pro Export</name><time>${DateTime.now().toIso8601String()}</time></metadata>');

      for (final wp in _waypoints) {
        buffer.writeln('<wpt lat="${wp.latitude}" lon="${wp.longitude}">');
        buffer.writeln('<ele>${wp.altitude}</ele>');
        buffer.writeln('<name>${_xmlEscape(wp.name)}</name>');
        buffer.writeln('<desc>${_xmlEscape(wp.notes)}</desc>');
        buffer.writeln('<time>${wp.createdAt.toIso8601String()}</time>');
        buffer.writeln('</wpt>');
      }

      for (final track in _tracks) {
        if (track.points.isEmpty) continue;
        buffer.writeln('<trk>');
        buffer.writeln('<name>${_xmlEscape(track.name)}</name>');
        buffer.writeln('<trkseg>');
        for (final p in track.points) {
          buffer.writeln('<trkpt lat="${p.latitude}" lon="${p.longitude}"><ele>${p.altitude}</ele><time>${p.timestamp.toIso8601String()}</time></trkpt>');
        }
        buffer.writeln('</trkseg></trk>');
      }

      buffer.writeln('</gpx>');

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/site_survey_export_$timestamp.gpx');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'GeoCompass Pro - GPX Export');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPX exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPX export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    if (_waypoints.isEmpty && _tracks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      final buffer = StringBuffer();
      buffer.writeln('Type,Name,Latitude,Longitude,Altitude,Notes,Created');
      for (final wp in _waypoints) {
        buffer.writeln('"Waypoint","${_csvEscape(wp.name)}",${wp.latitude},${wp.longitude},${wp.altitude},"${_csvEscape(wp.notes)}","${wp.createdAt.toIso8601String()}"');
      }
      for (final track in _tracks) {
        for (int i = 0; i < track.points.length; i++) {
          final p = track.points[i];
          buffer.writeln('"Track","${_csvEscape(track.name)}_pt${i+1}",${p.latitude},${p.longitude},${p.altitude},"","${p.timestamp.toIso8601String()}"');
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/site_survey_export_$timestamp.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'GeoCompass Pro - CSV Export');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportJson() async {
    if (_waypoints.isEmpty && _tracks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      final data = {
        'exportedAt': DateTime.now().toIso8601String(),
        'app': 'GeoCompass Pro',
        'version': '4.0.0',
        'waypoints': _waypoints.map((w) => w.toJson()).toList(),
        'tracks': _tracks.map((t) => t.toJson()).toList(),
      };
      final content = const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/site_survey_export_$timestamp.json');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'GeoCompass Pro - JSON Export');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _xmlEscape(String text) {
    return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
  }

  String _csvEscape(String text) {
    return text.replaceAll('"', '""');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import / Export'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  const Text('Export', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _waypoints.isEmpty && _tracks.isEmpty ? null : () => _exportKml(),
                    icon: const Icon(Icons.map),
                    label: const Text('Export as KML (Google Earth)'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _waypoints.isEmpty && _tracks.isEmpty ? null : () => _exportGpx(),
                    icon: const Icon(Icons.explore),
                    label: const Text('Export as GPX (GPS)'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _waypoints.isEmpty && _tracks.isEmpty ? null : () => _exportCsv(),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export as CSV (Spreadsheet)'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _waypoints.isEmpty && _tracks.isEmpty ? null : () => _exportJson(),
                    icon: const Icon(Icons.code),
                    label: const Text('Export as JSON (Data)'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.place, color: Colors.cyan, size: 32),
              const SizedBox(height: 8),
              Text('${_waypoints.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Waypoints', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Container(width: 1, height: 50, color: Colors.grey[700]),
          Column(
            children: [
              const Icon(Icons.timeline, color: Colors.orange, size: 32),
              const SizedBox(height: 8),
              Text('${_tracks.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Tracks', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
