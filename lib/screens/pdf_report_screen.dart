import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/waypoint_model.dart';
import '../models/track_model.dart';
import '../services/api_waypoint_service.dart';
import '../services/track_service.dart';
import '../services/gps_service.dart';
import '../utils/geo_utils.dart';

class PdfReportScreen extends StatefulWidget {
  const PdfReportScreen({Key? key}) : super(key: key);

  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  List<Waypoint> _waypoints = [];
  List<Track> _tracks = [];
  bool _includeWaypoints = true;
  bool _includeTracks = true;
  bool _includeLocation = true;
  final _titleController = TextEditingController(text: 'Site Survey Report');
  final _notesController = TextEditingController();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wpService = context.read<ApiWaypointService>();
    final trService = TrackService();
    await trService.initialize();

    final wps = await wpService.getAllWaypoints();
    final trs = await trService.getAllTracks();

    if (mounted) {
      setState(() {
        _waypoints = wps;
        _tracks = trs;
      });
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _isGenerating = true);

    try {
      final gps = context.read<GpsService>();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(_titleController.text, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated: ${DateTime.now().toString().substring(0, 19)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  pw.Divider(),
                ],
              ),
            ),

            // Current Location
            if (_includeLocation && gps.latitude != null) ...[
              pw.Header(level: 1, text: 'Current Location'),
              pw.Text('Latitude: ${gps.latitude!.toStringAsFixed(6)}'),
              pw.Text('Longitude: ${gps.longitude!.toStringAsFixed(6)}'),
              if (gps.altitude != null) pw.Text('Altitude: ${gps.altitude!.toStringAsFixed(1)} m'),
              if (gps.address != null) pw.Text('Address: ${gps.address}'),
              pw.SizedBox(height: 16),
            ],

            // Notes
            if (_notesController.text.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Notes'),
              pw.Text(_notesController.text),
              pw.SizedBox(height: 16),
            ],

            // Waypoints Table
            if (_includeWaypoints && _waypoints.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Waypoints (${_waypoints.length})'),
              pw.Table.fromTextArray(
                headers: ['#', 'Name', 'Latitude', 'Longitude', 'Alt (m)', 'Bearing'],
                data: _waypoints.asMap().entries.map((e) => [
                  '${e.key + 1}',
                  e.value.name,
                  e.value.latitude.toStringAsFixed(6),
                  e.value.longitude.toStringAsFixed(6),
                  e.value.altitude.toStringAsFixed(1),
                  '${e.value.bearing.toStringAsFixed(1)}°',
                ]).toList(),
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              ),
              pw.SizedBox(height: 16),
            ],

            // Tracks Table
            if (_includeTracks && _tracks.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Tracks (${_tracks.length})'),
              pw.Table.fromTextArray(
                headers: ['#', 'Name', 'Points', 'Distance', 'Duration', 'Date'],
                data: _tracks.asMap().entries.map((e) => [
                  '${e.key + 1}',
                  e.value.name,
                  '${e.value.points.length}',
                  GeoUtils.formatDistance(e.value.totalDistance),
                  '${e.value.duration.inMinutes}min',
                  '${e.value.startTime.day}/${e.value.startTime.month}/${e.value.startTime.year}',
                ]).toList(),
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              ),
              pw.SizedBox(height: 16),
            ],

            // Summary
            pw.Header(level: 1, text: 'Summary'),
            pw.Text('Total Waypoints: ${_waypoints.length}'),
            pw.Text('Total Tracks: ${_tracks.length}'),
            if (_tracks.isNotEmpty)
              pw.Text('Total Distance: ${GeoUtils.formatDistance(_tracks.fold(0.0, (sum, t) => sum + t.totalDistance))}'),
          ],
        ),
      );

      // Save and share
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/survey_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        setState(() => _isGenerating = false);
        await Share.shareXFiles([XFile(file.path)], text: _titleController.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Report'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Report Title',
                labelStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Include in Report:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSwitch('Current Location', _includeLocation, (v) => setState(() => _includeLocation = v)),
            _buildSwitch('Waypoints (${_waypoints.length})', _includeWaypoints, (v) => setState(() => _includeWaypoints = v)),
            _buildSwitch('Tracks (${_tracks.length})', _includeTracks, (v) => setState(() => _includeTracks = v)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePdf,
              icon: _isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGenerating ? 'Generating...' : 'Generate & Share PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.cyan,
    );
  }
}
