import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';


import '../services/api_waypoint_service.dart';
import '../services/track_service.dart';
import '../services/gps_service.dart';

class ExcelExportScreen extends StatefulWidget {
  const ExcelExportScreen({Key? key}) : super(key: key);

  @override
  State<ExcelExportScreen> createState() => _ExcelExportScreenState();
}

class _ExcelExportScreenState extends State<ExcelExportScreen> {
  bool _includeWaypoints = true;
  bool _includeTracks = true;
  bool _includeCurrentLocation = true;
  bool _isExporting = false;
  String? _exportStatus;

  Future<void> _exportToExcel() async {
    setState(() {
      _isExporting = true;
      _exportStatus = 'Generating Excel file...';
    });

    try {
      final excel = Excel.createExcel();

      if (_includeWaypoints) {
        await _addWaypointsSheet(excel);
      }

      if (_includeTracks) {
        await _addTracksSheet(excel);
      }

      if (_includeCurrentLocation) {
        await _addCurrentLocationSheet(excel);
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/survey_export_$timestamp.xlsx');
      
      final fileBytes = excel.save();
      await file.writeAsBytes(fileBytes!);

      setState(() {
        _exportStatus = 'Export complete!';
      });

      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Complete'),
            content: Text('File saved to:\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Share'),
              ),
            ],
          ),
        );

        if (result == true) {
          await Share.shareXFiles([XFile(file.path)]);
        }
      }
    } catch (e) {
      setState(() {
        _exportStatus = 'Error: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _addWaypointsSheet(Excel excel) async {
    final sheet = excel['Waypoints'];

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      TextCellValue('Altitude (m)'),
      TextCellValue('Bearing (°)'),
      TextCellValue('Notes'),
      TextCellValue('Created At'),
      TextCellValue('Updated At'),
    ]);

    final service = context.read<ApiWaypointService>();
    final waypoints = await service.getAllWaypoints();

    for (final wp in waypoints) {
      sheet.appendRow([
        TextCellValue(wp.name),
        DoubleCellValue(wp.latitude),
        DoubleCellValue(wp.longitude),
        DoubleCellValue(wp.altitude),
        DoubleCellValue(wp.bearing),
        TextCellValue(wp.notes),
        TextCellValue(wp.createdAt.toString()),
        TextCellValue(wp.updatedAt.toString()),
      ]);
    }
  }

  Future<void> _addTracksSheet(Excel excel) async {
    final sheet = excel['Tracks'];

    sheet.appendRow([
      TextCellValue('Track Name'),
      TextCellValue('Point Index'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      TextCellValue('Altitude (m)'),
      TextCellValue('Timestamp'),
      TextCellValue('Speed (m/s)'),
      TextCellValue('Accuracy (m)'),
    ]);

    final service = TrackService();
    final tracks = await service.getAllTracks();

    for (final track in tracks) {
      for (int i = 0; i < track.points.length; i++) {
        final point = track.points[i];
        sheet.appendRow([
          TextCellValue(track.name),
          IntCellValue(i + 1),
          DoubleCellValue(point.latitude),
          DoubleCellValue(point.longitude),
          DoubleCellValue(point.altitude),
          TextCellValue(point.timestamp.toString()),
          DoubleCellValue(point.speed ?? 0),
          DoubleCellValue(point.accuracy ?? 0),
        ]);
      }
    }
  }

  Future<void> _addCurrentLocationSheet(Excel excel) async {
    final sheet = excel['Current Location'];
    final gpsService = context.read<GpsService>();

    sheet.appendRow([
      TextCellValue('Parameter'),
      TextCellValue('Value'),
    ]);

    sheet.appendRow([
      TextCellValue('Export Time'),
      TextCellValue(DateTime.now().toString()),
    ]);

    if (gpsService.currentPosition != null) {
      final pos = gpsService.currentPosition!;
      sheet.appendRow([TextCellValue('Latitude'), DoubleCellValue(pos.latitude)]);
      sheet.appendRow([TextCellValue('Longitude'), DoubleCellValue(pos.longitude)]);
      sheet.appendRow([TextCellValue('Altitude (m)'), DoubleCellValue(pos.altitude)]);
      sheet.appendRow([TextCellValue('Accuracy (m)'), DoubleCellValue(pos.accuracy)]);
      sheet.appendRow([TextCellValue('Speed (m/s)'), DoubleCellValue(pos.speed)]);
      sheet.appendRow([TextCellValue('Timestamp'), TextCellValue(pos.timestamp.toString())]);
    } else {
      sheet.appendRow([TextCellValue('Status'), TextCellValue('No GPS fix')]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Excel Export'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Options',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Waypoints', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'All saved waypoints with coordinates',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      value: _includeWaypoints,
                      onChanged: (value) => setState(() => _includeWaypoints = value ?? false),
                      activeColor: Colors.cyan,
                    ),
                    CheckboxListTile(
                      title: const Text('Track History', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'All recorded track points',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      value: _includeTracks,
                      onChanged: (value) => setState(() => _includeTracks = value ?? false),
                      activeColor: Colors.cyan,
                    ),
                    CheckboxListTile(
                      title: const Text('Current Location', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'Current GPS position',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      value: _includeCurrentLocation,
                      onChanged: (value) => setState(() => _includeCurrentLocation = value ?? false),
                      activeColor: Colors.cyan,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isExporting)
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Colors.cyan),
                      const SizedBox(height: 16),
                      Text(
                        _exportStatus ?? 'Exporting...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            if (_exportStatus != null && !_isExporting)
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        _exportStatus!,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isExporting ? null : _exportToExcel,
              icon: const Icon(Icons.file_download),
              label: const Text('Export to Excel'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

