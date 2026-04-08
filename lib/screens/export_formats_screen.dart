
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/waypoint_model.dart';
import '../models/track_model.dart';
import '../services/waypoint_service.dart';
import '../services/track_service.dart';
import '../services/gps_service.dart';
import 'package:provider/provider.dart';

class ExportFormatsScreen extends StatefulWidget {
  const ExportFormatsScreen({super.key});

  @override
  State<ExportFormatsScreen> createState() => _ExportFormatsScreenState();
}

class _ExportFormatsScreenState extends State<ExportFormatsScreen> {
  bool _includeWaypoints = true;
  bool _includeTracks = true;
  bool _includeCurrentLocation = true;
  String _selectedFormat = 'KML';
  bool _isExporting = false;

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final waypointService = context.read<WaypointService>();
      final trackService = context.read<TrackService>();
      final gpsService = context.read<GpsService>();

      final waypoints = await waypointService.getAllWaypoints();
      final tracks = await trackService.getAllTracks();
      final currentPos = gpsService.currentPosition;

      String exportContent = '';
      String fileExtension = '';

      if (_selectedFormat == 'KML') {
        exportContent = _generateKML(waypoints, tracks, currentPos);
        fileExtension = 'kml';
      } else if (_selectedFormat == 'GPX') {
        exportContent = _generateGPX(waypoints, tracks, currentPos);
        fileExtension = 'gpx';
      } else if (_selectedFormat == 'CSV') {
        exportContent = _generateCSV(waypoints, tracks, currentPos);
        fileExtension = 'csv';
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/export_$timestamp.$fileExtension');
      await file.writeAsString(exportContent);

      await Share.shareXFiles([XFile(file.path)], text: 'Exported $_selectedFormat data');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $_selectedFormat successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }

    setState(() => _isExporting = false);
  }

  String _generateKML(List<Waypoint> waypoints, List<Track> tracks, dynamic currentPos) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('<Document>');
    buffer.writeln('  <name>Site Surveyor Export</name>');

    if (_includeWaypoints) {
      for (final wp in waypoints) {
        buffer.writeln('  <Placemark>');
        buffer.writeln('    <name>${_escapeXml(wp.name)}</name>');
        buffer.writeln('    <description>${_escapeXml(wp.notes)}</description>');
        buffer.writeln('    <Point><coordinates>${wp.longitude},${wp.latitude},${wp.altitude}</coordinates></Point>');
        buffer.writeln('  </Placemark>');
      }
    }

    if (_includeTracks && tracks.isNotEmpty) {
      for (final track in tracks) {
        buffer.writeln('  <Placemark>');
        buffer.writeln('    <name>${_escapeXml(track.name)}</name>');
        buffer.writeln('    <LineString>');
        buffer.write('      <coordinates>');
        for (final point in track.points) {
          buffer.write('${point.longitude},${point.latitude},0 ');
        }
        buffer.writeln('</coordinates>');
        buffer.writeln('    </LineString>');
        buffer.writeln('  </Placemark>');
      }
    }

    if (_includeCurrentLocation && currentPos != null) {
      buffer.writeln('  <Placemark>');
      buffer.writeln('    <name>Current Location</name>');
      buffer.writeln('    <Point><coordinates>${currentPos.longitude},${currentPos.latitude},${currentPos.altitude}</coordinates></Point>');
      buffer.writeln('  </Placemark>');
    }

    buffer.writeln('</Document>');
    buffer.writeln('</kml>');
    return buffer.toString();
  }

  String _generateGPX(List<Waypoint> waypoints, List<Track> tracks, dynamic currentPos) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="SiteSurveyorCompass">');

    if (_includeWaypoints) {
      for (final wp in waypoints) {
        buffer.writeln('  <wpt lat="${wp.latitude}" lon="${wp.longitude}">');
        buffer.writeln('    <name>${_escapeXml(wp.name)}</name>');
        if (wp.notes.isNotEmpty) buffer.writeln('    <desc>${_escapeXml(wp.notes)}</desc>');
        buffer.writeln('    <ele>${wp.altitude}</ele>');
        buffer.writeln('  </wpt>');
      }
    }

    if (_includeTracks && tracks.isNotEmpty) {
      for (final track in tracks) {
        buffer.writeln('  <trk>');
        buffer.writeln('    <name>${_escapeXml(track.name)}</name>');
        buffer.writeln('    <trkseg>');
        for (final point in track.points) {
          buffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}">');
          buffer.writeln('      </trkpt>');
        }
        buffer.writeln('    </trkseg>');
        buffer.writeln('  </trk>');
      }
    }

    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  String _generateCSV(List<Waypoint> waypoints, List<Track> tracks, dynamic currentPos) {
    final buffer = StringBuffer();
    
    if (_includeWaypoints) {
      buffer.writeln('Waypoints');
      buffer.writeln('Name,Latitude,Longitude,Altitude,Description');
      for (final wp in waypoints) {
        buffer.writeln('${_escapeCsv(wp.name)},${wp.latitude},${wp.longitude},${wp.altitude},${_escapeCsv(wp.notes)}');
      }
      buffer.writeln();
    }

    if (_includeTracks && tracks.isNotEmpty) {
      buffer.writeln('Tracks');
      buffer.writeln('Track Name,Point Index,Latitude,Longitude');
      for (final track in tracks) {
        for (int i = 0; i < track.points.length; i++) {
          final point = track.points[i];
          buffer.writeln('${_escapeCsv(track.name)},$i,${point.latitude},${point.longitude}');
        }
      }
      buffer.writeln();
    }

    if (_includeCurrentLocation && currentPos != null) {
      buffer.writeln('Current Location');
      buffer.writeln('Latitude,Longitude,Altitude,Accuracy');
      buffer.writeln('${currentPos.latitude},${currentPos.longitude},${currentPos.altitude},${currentPos.accuracy}');
    }

    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _escapeCsv(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Formats'),
        backgroundColor: const Color(0xFF1a1a2e),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Select Format', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                _buildFormatChip('KML'),
                _buildFormatChip('GPX'),
                _buildFormatChip('CSV'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Include Data', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSwitch('Waypoints', _includeWaypoints, (v) => setState(() => _includeWaypoints = v)),
            _buildSwitch('Tracks', _includeTracks, (v) => setState(() => _includeTracks = v)),
            _buildSwitch('Current Location', _includeCurrentLocation, (v) => setState(() => _includeCurrentLocation = v)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportData,
                icon: const Icon(Icons.download),
                label: Text(_isExporting ? 'Exporting...' : 'Export $_selectedFormat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatChip(String format) {
    final isSelected = _selectedFormat == format;
    return ChoiceChip(
      label: Text(format),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedFormat = format),
      selectedColor: Colors.cyanAccent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.cyanAccent,
    );
  }
}
