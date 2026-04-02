import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/waypoint_model.dart';
import '../services/api_waypoint_service.dart';
import '../services/gps_service.dart';
import '../utils/geo_utils.dart';
import 'weather_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({Key? key}) : super(key: key);

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Waypoint> _waypoints = [];

  // Bearing calculator controllers - created once, disposed properly
  final TextEditingController _lat1Controller = TextEditingController();
  final TextEditingController _lon1Controller = TextEditingController();
  final TextEditingController _lat2Controller = TextEditingController();
  final TextEditingController _lon2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadWaypoints();
  }

  Future<void> _loadWaypoints() async {
    final service = context.read<ApiWaypointService>();
    final waypoints = await service.getAllWaypoints();
    if (mounted) {
      setState(() => _waypoints = waypoints);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lat1Controller.dispose();
    _lon1Controller.dispose();
    _lat2Controller.dispose();
    _lon2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.explore), text: 'Bearing'),
            Tab(icon: Icon(Icons.file_upload), text: 'Export'),
            Tab(icon: Icon(Icons.file_download), text: 'Import'),
            Tab(icon: Icon(Icons.show_chart), text: 'Altitude'),
            Tab(icon: Icon(Icons.sync_alt), text: 'Compare'),
            Tab(icon: Icon(Icons.cloud), text: 'Weather'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBearingCalculator(),
          _buildExportTab(),
          _buildImportTab(),
          _buildAltitudeChart(),
          _buildWaypointCompare(),
          const WeatherScreen(),
        ],
      ),
    );
  }

  // ========== BEARING CALCULATOR TAB ==========
  Widget _buildBearingCalculator() {
    String resultDistance = '';
    String resultBearing = '';

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Point A (Start)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyan)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lat1Controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lon1Controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final gps = context.read<GpsService>();
                        if (gps.latitude != null && gps.longitude != null) {
                          _lat1Controller.text = gps.latitude!.toStringAsFixed(6);
                          _lon1Controller.text = gps.longitude!.toStringAsFixed(6);
                        }
                      },
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Use current'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Point B (End)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lat2Controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _lon2Controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  final lat1 = double.tryParse(_lat1Controller.text);
                  final lon1 = double.tryParse(_lon1Controller.text);
                  final lat2 = double.tryParse(_lat2Controller.text);
                  final lon2 = double.tryParse(_lon2Controller.text);

                  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid coordinates')),
                    );
                    return;
                  }

                  setLocalState(() {
                    final dist = GeoUtils.calculateDistance(lat1, lon1, lat2, lon2);
                    final bear = GeoUtils.calculateBearing(lat1, lon1, lat2, lon2);
                    resultDistance = GeoUtils.formatDistance(dist);
                    resultBearing = '${bear.toStringAsFixed(2)}° ${GeoUtils.bearingToCompass(bear)}';
                  });
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Calculate'),
              ),
              const SizedBox(height: 24),
              if (resultDistance.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.straighten, color: Colors.cyan, size: 28),
                          const SizedBox(height: 8),
                          Text(resultDistance, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('Distance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[700]),
                      Column(
                        children: [
                          const Icon(Icons.explore, color: Colors.orange, size: 28),
                          const SizedBox(height: 8),
                          Text(resultBearing, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const Text('Bearing', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ========== IMPORT TAB ==========
  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload, size: 48, color: Colors.green),
                const SizedBox(height: 8),
                const Text(
                  'Import Data',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Supported: JSON, GPX, KML, CSV',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quick Import Methods', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showJsonImportDialog(),
            icon: const Icon(Icons.code),
            label: const Text('Paste JSON Data'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.green),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showGpxImportDialog(),
            icon: const Icon(Icons.explore),
            label: const Text('Paste GPX Data'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.orange),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _showKmlImportDialog(),
            icon: const Icon(Icons.map),
            label: const Text('Paste KML Data'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.blue),
          ),
          const SizedBox(height: 24),
          const Text('CSV Format', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Name,Latitude,Longitude,Altitude\nCorner A,28.6139,77.2090,216\nCorner B,28.6145,77.2095,218',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showJsonImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import JSON'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste JSON waypoint data here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                final data = jsonDecode(controller.text);
                final service = context.read<ApiWaypointService>();
                int count = 0;
                List<dynamic> waypoints;
                if (data is List) {
                  waypoints = data;
                } else if (data is Map && data.containsKey('waypoints')) {
                  waypoints = data['waypoints'] as List<dynamic>;
                } else {
                  waypoints = [data];
                }
                for (final w in waypoints) {
                  final wp = Waypoint.fromJson(w as Map<String, dynamic>);
                  await service.createWaypoint(
                    name: wp.name,
                    bearing: wp.bearing,
                    latitude: wp.latitude,
                    longitude: wp.longitude,
                    altitude: wp.altitude,
                    notes: wp.notes,
                  );
                  count++;
                }
                if (mounted) {
                  Navigator.pop(context);
                  _loadWaypoints();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Imported $count waypoints')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import error: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showGpxImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import GPX'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste GPX data here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                final content = controller.text;
                final service = context.read<ApiWaypointService>();
                int count = 0;
                final wptRegex = RegExp(r'<wpt\s+lat="([^"]+)"\s+lon="([^"]+)">\s*(?:<ele>([^<]*)</ele>)?\s*<name>([^<]*)</name>', dotAll: true);
                for (final match in wptRegex.allMatches(content)) {
                  await service.createWaypoint(
                    name: match.group(4) ?? 'Imported WP',
                    bearing: 0,
                    latitude: double.parse(match.group(1)!),
                    longitude: double.parse(match.group(2)!),
                    altitude: double.tryParse(match.group(3) ?? '') ?? 0,
                  );
                  count++;
                }
                if (mounted) {
                  Navigator.pop(context);
                  _loadWaypoints();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Imported $count waypoints from GPX')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('GPX import error: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showKmlImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import KML'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste KML data here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                final content = controller.text;
                final service = context.read<ApiWaypointService>();
                int count = 0;
                final placemarkRegex = RegExp(r'<Placemark>\s*<name>([^<]*)</name>(?:.*?<Point>\s*<coordinates>([^<]*)</coordinates>)', dotAll: true);
                for (final match in placemarkRegex.allMatches(content)) {
                  final coords = match.group(2)!.split(',');
                  if (coords.length >= 2) {
                    await service.createWaypoint(
                      name: match.group(1) ?? 'Imported WP',
                      bearing: 0,
                      longitude: double.parse(coords[0]),
                      latitude: double.parse(coords[1]),
                      altitude: coords.length >= 3 ? double.tryParse(coords[2]) ?? 0 : 0,
                    );
                    count++;
                  }
                }
                if (mounted) {
                  Navigator.pop(context);
                  _loadWaypoints();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Imported $count waypoints from KML')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('KML import error: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  // ========== EXPORT TAB ==========
  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.place, size: 48, color: Colors.cyan),
                const SizedBox(height: 8),
                Text(
                  '${_waypoints.length} waypoints loaded',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _waypoints.isEmpty ? null : () => _exportAsCsv(),
            icon: const Icon(Icons.table_chart),
            label: const Text('Export as CSV'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _waypoints.isEmpty ? null : () => _exportAsJson(),
            icon: const Icon(Icons.code),
            label: const Text('Export as JSON'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _waypoints.isEmpty ? null : () => _copyToClipboard(),
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 24),
          if (_waypoints.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waypoint Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _summaryRow('Total waypoints', '${_waypoints.length}'),
                  if (_waypoints.isNotEmpty) ...[
                    _summaryRow('Highest altitude', '${_waypoints.map((w) => w.altitude).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} m'),
                    _summaryRow('Lowest altitude', '${_waypoints.map((w) => w.altitude).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)} m'),
                    _summaryRow('Newest', DateFormat('MMM dd, yyyy').format(_waypoints.first.createdAt)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _exportAsCsv() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Name,Bearing,Latitude,Longitude,Altitude,Notes,Created,Updated');
      for (final wp in _waypoints) {
        buffer.writeln(
          '"${wp.name}",${wp.bearing},${wp.latitude},${wp.longitude},${wp.altitude},"${wp.notes}","${wp.createdAt.toIso8601String()}","${wp.updatedAt?.toIso8601String() ?? ''}"',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/waypoints_export.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'Site Surveyor - Waypoints Export (CSV)');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported and ready to share')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  Future<void> _exportAsJson() async {
    try {
      final jsonList = _waypoints.map((wp) => wp.toJson()).toList();
      final content = const JsonEncoder.withIndent('  ').convert(jsonList);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/waypoints_export.json');
      await file.writeAsString(content);

      await Share.shareXFiles([XFile(file.path)], text: 'Site Surveyor - Waypoints Export (JSON)');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON exported and ready to share')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    final buffer = StringBuffer();
    for (final wp in _waypoints) {
      buffer.writeln('${wp.name}: ${wp.latitude.toStringAsFixed(6)}, ${wp.longitude.toStringAsFixed(6)} (Alt: ${wp.altitude.toStringAsFixed(1)}m)');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waypoints copied to clipboard')),
      );
    }
  }

  // ========== ALTITUDE CHART TAB ==========
  Widget _buildAltitudeChart() {
    if (_waypoints.isEmpty) {
      return const Center(
        child: Text('No waypoints to display', style: TextStyle(color: Colors.grey)),
      );
    }

    final sorted = List<Waypoint>.from(_waypoints)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].altitude));
    }

    final minAlt = sorted.map((w) => w.altitude).reduce((a, b) => a < b ? a : b);
    final maxAlt = sorted.map((w) => w.altitude).reduce((a, b) => a > b ? a : b);
    final range = maxAlt - minAlt;
    final padding = range > 0 ? range * 0.1 : 10;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Altitude Profile (${sorted.length} waypoints)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[800]!, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[800]!, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(0)}m',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 0 && i < sorted.length) {
                          return Text(
                            '#${i + 1}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[800]!)),
                minY: (minAlt - padding).clamp(0, double.infinity),
                maxY: maxAlt + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.cyan,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.cyan,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.cyan.withOpacity(0.15),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final i = spot.x.toInt();
                        final wp = sorted[i];
                        return LineTooltipItem(
                          '${wp.name}\n${wp.altitude.toStringAsFixed(1)}m',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Altitude stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statChip('Min', '${minAlt.toStringAsFixed(0)}m', Colors.blue),
              _statChip('Max', '${maxAlt.toStringAsFixed(0)}m', Colors.red),
              _statChip('Avg', '${(sorted.fold<double>(0, (s, w) => s + w.altitude) / sorted.length).toStringAsFixed(0)}m', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  // ========== WAYPOINT COMPARE TAB ==========
  Waypoint? _selectedWp1;
  Waypoint? _selectedWp2;

  Widget _buildWaypointCompare() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Select two waypoints to compare:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              // Waypoint 1 selector
              _waypointSelector(
                'Waypoint A',
                _selectedWp1,
                (wp) => setLocalState(() => _selectedWp1 = wp),
                Colors.cyan,
              ),
              const SizedBox(height: 12),
              const Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
              const SizedBox(height: 12),
              // Waypoint 2 selector
              _waypointSelector(
                'Waypoint B',
                _selectedWp2,
                (wp) => setLocalState(() => _selectedWp2 = wp),
                Colors.orange,
              ),
              const SizedBox(height: 24),
              // Results
              if (_selectedWp1 != null && _selectedWp2 != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('Comparison Results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 16),
                      _comparisonRow(
                        'Distance',
                        GeoUtils.formatDistance(GeoUtils.calculateDistance(
                          _selectedWp1!.latitude, _selectedWp1!.longitude,
                          _selectedWp2!.latitude, _selectedWp2!.longitude,
                        )),
                      ),
                      _comparisonRow(
                        'Bearing (A→B)',
                        '${GeoUtils.calculateBearing(_selectedWp1!.latitude, _selectedWp1!.longitude, _selectedWp2!.latitude, _selectedWp2!.longitude).toStringAsFixed(1)}° ${GeoUtils.bearingToCompass(GeoUtils.calculateBearing(_selectedWp1!.latitude, _selectedWp1!.longitude, _selectedWp2!.latitude, _selectedWp2!.longitude))}',
                      ),
                      _comparisonRow(
                        'Bearing (B→A)',
                        '${GeoUtils.calculateBearing(_selectedWp2!.latitude, _selectedWp2!.longitude, _selectedWp1!.latitude, _selectedWp1!.longitude).toStringAsFixed(1)}° ${GeoUtils.bearingToCompass(GeoUtils.calculateBearing(_selectedWp2!.latitude, _selectedWp2!.longitude, _selectedWp1!.latitude, _selectedWp1!.longitude))}',
                      ),
                      _comparisonRow(
                        'Altitude difference',
                        '${(_selectedWp1!.altitude - _selectedWp2!.altitude).toStringAsFixed(1)} m',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _waypointSelector(String label, Waypoint? selected, ValueChanged<Waypoint?> onChanged, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected != null ? color.withOpacity(0.5) : Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButton<Waypoint>(
            isExpanded: true,
            value: selected,
            hint: Text('Select $label', style: const TextStyle(color: Colors.grey)),
            dropdownColor: Colors.grey[850],
            items: _waypoints.map((wp) => DropdownMenuItem(
              value: wp,
              child: Text(wp.name, style: const TextStyle(color: Colors.white)),
            )).toList(),
            onChanged: onChanged,
          ),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
