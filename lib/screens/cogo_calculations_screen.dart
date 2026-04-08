import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../models/waypoint_model.dart';
import '../services/api_waypoint_service.dart';

class CogoCalculationsScreen extends StatefulWidget {
  const CogoCalculationsScreen({Key? key}) : super(key: key);

  @override
  State<CogoCalculationsScreen> createState() => _CogoCalculationsScreenState();
}

class _CogoCalculationsScreenState extends State<CogoCalculationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COGO Calculations'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Forward'),
            Tab(text: 'Inverse'),
            Tab(text: 'Intersection'),
            Tab(text: 'Resection'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ForwardCalculationTab(),
          InverseCalculationTab(),
          IntersectionCalculationTab(),
          ResectionCalculationTab(),
        ],
      ),
    );
  }
}

// Forward Calculation Tab (Bearing + Distance to Coordinates)
class ForwardCalculationTab extends StatefulWidget {
  const ForwardCalculationTab({Key? key}) : super(key: key);

  @override
  State<ForwardCalculationTab> createState() => _ForwardCalculationTabState();
}

class _ForwardCalculationTabState extends State<ForwardCalculationTab> {
  final _startLatController = TextEditingController();
  final _startLngController = TextEditingController();
  final _bearingController = TextEditingController();
  final _distanceController = TextEditingController();

  double? _resultLat;
  double? _resultLng;

  void _calculateForward() {
    final startLat = double.tryParse(_startLatController.text);
    final startLng = double.tryParse(_startLngController.text);
    final bearing = double.tryParse(_bearingController.text);
    final distance = double.tryParse(_distanceController.text);

    // IMPROVED: Better input validation
    if (startLat == null || startLng == null || bearing == null || distance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields with valid numbers')),
      );
      return;
    }

    // Validate coordinate ranges
    if (startLat < -90 || startLat > 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitude must be between -90° and 90°')),
      );
      return;
    }

    if (startLng < -180 || startLng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Longitude must be between -180° and 180°')),
      );
      return;
    }

    // Validate bearing
    final normalizedBearing = bearing % 360;
    if (normalizedBearing < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bearing must be between 0° and 360°')),
      );
      return;
    }

    // Validate distance
    if (distance <= 0 || distance > 10000000) { // Max 10,000 km
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Distance must be between 0 and 10,000,000 meters')),
      );
      return;
    }

    try {
      // FIX: Improved forward calculation using spherical approximation with corrections
      final bearingRad = normalizedBearing * math.pi / 180;

      // Use WGS84 mean radius for better accuracy
      const earthRadius = 6371008.8; // WGS84 mean radius in meters

      final startLatRad = startLat * math.pi / 180;
      final startLngRad = startLng * math.pi / 180;

      // Convert distance to angular distance
      final angularDistance = distance / earthRadius;

      // Calculate new latitude (simplified but accurate for most surveying distances)
      final newLatRad = math.asin(
        math.sin(startLatRad) * math.cos(angularDistance) +
        math.cos(startLatRad) * math.sin(angularDistance) * math.cos(bearingRad),
      );

      // Calculate new longitude
      final newLngRad = startLngRad + math.atan2(
        math.sin(bearingRad) * math.sin(angularDistance) * math.cos(startLatRad),
        math.cos(angularDistance) - math.sin(startLatRad) * math.sin(newLatRad),
      );

      // Convert back to degrees and normalize longitude
      final newLat = newLatRad * 180 / math.pi;
      final newLng = ((newLngRad * 180 / math.pi) + 180) % 360 - 180;

      // Validate results
      if (newLat.isNaN || newLng.isNaN || newLat.abs() > 90 || newLng.abs() > 180) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid calculation result - check inputs')),
        );
        return;
      }

      setState(() {
        _resultLat = newLat;
        _resultLng = newLng;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calculation error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Forward Calculation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calculate new coordinates from starting point, bearing, and distance.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Input fields
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startLatController,
                  decoration: const InputDecoration(
                    labelText: 'Start Latitude',
                    hintText: '28.6139',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _startLngController,
                  decoration: const InputDecoration(
                    labelText: 'Start Longitude',
                    hintText: '77.2090',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bearingController,
                  decoration: const InputDecoration(
                    labelText: 'Bearing (°)',
                    hintText: '45.0',
                    suffixText: '°',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _distanceController,
                  decoration: const InputDecoration(
                    labelText: 'Distance (m)',
                    hintText: '100.0',
                    suffixText: 'm',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Calculate button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _calculateForward,
              child: const Text('Calculate'),
            ),
          ),

          // Results
          if (_resultLat != null && _resultLng != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Result Coordinates:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Latitude:'),
                      Text(
                        _resultLat!.toStringAsFixed(6),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Longitude:'),
                      Text(
                        _resultLng!.toStringAsFixed(6),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${_resultLat!.toStringAsFixed(6)}, ${_resultLng!.toStringAsFixed(6)}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coordinates copied to clipboard')),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (_resultLat == null || _resultLng == null) return;
                      try {
                        final apiService = Provider.of<ApiWaypointService>(context, listen: false);
                        await apiService.createWaypoint(
                          name: 'Calculated Point',
                          latitude: _resultLat!,
                          longitude: _resultLng!,
                          altitude: 0,
                          bearing: 0,
                          notes: 'Created from COGO calculation',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Waypoint created successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to create waypoint: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Create Waypoint'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _startLatController.dispose();
    _startLngController.dispose();
    _bearingController.dispose();
    _distanceController.dispose();
    super.dispose();
  }
}

// Inverse Calculation Tab (Coordinates to Bearing + Distance)
class InverseCalculationTab extends StatefulWidget {
  const InverseCalculationTab({Key? key}) : super(key: key);

  @override
  State<InverseCalculationTab> createState() => _InverseCalculationTabState();
}

class _InverseCalculationTabState extends State<InverseCalculationTab> {
  final _startLatController = TextEditingController();
  final _startLngController = TextEditingController();
  final _endLatController = TextEditingController();
  final _endLngController = TextEditingController();

  double? _resultBearing;
  double? _resultDistance;

  void _calculateInverse() {
    final startLat = double.tryParse(_startLatController.text);
    final startLng = double.tryParse(_startLngController.text);
    final endLat = double.tryParse(_endLatController.text);
    final endLng = double.tryParse(_endLngController.text);

    // IMPROVED: Better input validation
    if (startLat == null || startLng == null || endLat == null || endLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields with valid numbers')),
      );
      return;
    }

    // Validate coordinate ranges
    if (startLat < -90 || startLat > 90 || endLat < -90 || endLat > 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latitude must be between -90° and 90°')),
      );
      return;
    }

    if (startLng < -180 || startLng > 180 || endLng < -180 || endLng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Longitude must be between -180° and 180°')),
      );
      return;
    }

    try {
      // FIX: Improved inverse calculation with better Haversine + bearing calculation
      final startLatRad = startLat * math.pi / 180;
      final startLngRad = startLng * math.pi / 180;
      final endLatRad = endLat * math.pi / 180;
      final endLngRad = endLng * math.pi / 180;

      // Calculate differences
      final dLng = endLngRad - startLngRad;

      // Calculate bearing with better precision
      final y = math.sin(dLng) * math.cos(endLatRad);
      final x = math.cos(startLatRad) * math.sin(endLatRad) -
                math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);
      final bearingRad = math.atan2(y, x);
      final bearing = (bearingRad * 180 / math.pi + 360) % 360;

      // FIX: More accurate distance calculation using improved Haversine
      final dLat = endLatRad - startLatRad;
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
                math.cos(startLatRad) * math.cos(endLatRad) *
                math.sin(dLng / 2) * math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

      // Use WGS84 mean radius for better accuracy
      const earthRadius = 6371008.8; // WGS84 mean radius in meters
      final distance = earthRadius * c;

      setState(() {
        _resultBearing = bearing;
        _resultDistance = distance;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calculation error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inverse Calculation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calculate bearing and distance between two coordinates.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Start point
          const Text('Start Point', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startLatController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '28.6139',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _startLngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '77.2090',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // End point
          const Text('End Point', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _endLatController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '28.7041',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _endLngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '77.1025',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Calculate button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _calculateInverse,
              child: const Text('Calculate'),
            ),
          ),

          // Results
          if (_resultBearing != null && _resultDistance != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bearing:'),
                      Text(
                        '${_resultBearing!.toStringAsFixed(1)}°',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Distance:'),
                      Text(
                        '${_resultDistance!.toStringAsFixed(2)} m',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: 'Bearing: ${_resultBearing!.toStringAsFixed(1)}°, Distance: ${_resultDistance!.toStringAsFixed(2)} m',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Results copied to clipboard')),
                  );
                },
                child: const Text('Copy Results'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _startLatController.dispose();
    _startLngController.dispose();
    _endLatController.dispose();
    _endLngController.dispose();
    super.dispose();
  }
}

// Intersection Calculation Tab
class IntersectionCalculationTab extends StatelessWidget {
  const IntersectionCalculationTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Intersection calculations coming soon...'),
    );
  }
}

// Resection Calculation Tab
class ResectionCalculationTab extends StatelessWidget {
  const ResectionCalculationTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Resection calculations coming soon...'),
    );
  }
}
