import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../services/gps_service.dart';
import '../providers/compass_provider.dart';
import '../utils/geo_utils.dart';

class StakeoutScreen extends StatefulWidget {
  const StakeoutScreen({Key? key}) : super(key: key);

  @override
  State<StakeoutScreen> createState() => _StakeoutScreenState();
}

class _StakeoutScreenState extends State<StakeoutScreen> with SingleTickerProviderStateMixin {
  final _targetLatController = TextEditingController();
  final _targetLngController = TextEditingController();
  final _toleranceController = TextEditingController(text: '0.5'); // meters

  double? _targetLat;
  double? _targetLng;
  double _tolerance = 0.5;

  Timer? _updateTimer;
  bool _isActive = false;
  bool _hasReachedTarget = false;

  // Animation for pulsing effect when close
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _targetLatController.dispose();
    _targetLngController.dispose();
    _toleranceController.dispose();
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startStakeout() {
    final lat = double.tryParse(_targetLatController.text);
    final lng = double.tryParse(_targetLngController.text);
    final tolerance = double.tryParse(_toleranceController.text);

    if (lat == null || lng == null || tolerance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid coordinates and tolerance')),
      );
      return;
    }

    if (tolerance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tolerance must be greater than 0')),
      );
      return;
    }

    setState(() {
      _targetLat = lat;
      _targetLng = lng;
      _tolerance = tolerance;
      _isActive = true;
      _hasReachedTarget = false;
    });

    // Start periodic updates
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkPosition();
    });
  }

  void _stopStakeout() {
    setState(() {
      _isActive = false;
      _hasReachedTarget = false;
    });
    _updateTimer?.cancel();
  }

  void _checkPosition() {
    final gpsService = context.read<GpsService>();
    final currentLat = gpsService.latitude;
    final currentLng = gpsService.longitude;
    final accuracy = gpsService.accuracy;

    if (currentLat == null || currentLng == null || _targetLat == null || _targetLng == null) {
      return;
    }

    // FIX: Better position validation and tolerance checking
    // Only use positions with reasonable accuracy
    if (accuracy != null && accuracy > 50) {
      return; // Skip if accuracy is poor (>50m)
    }

    final distance = GeoUtils.calculateDistance(currentLat, currentLng, _targetLat!, _targetLng!);

    // FIX: Use effective tolerance that considers GPS accuracy
    final effectiveTolerance = math.max(_tolerance, accuracy ?? _tolerance);

    if (distance <= effectiveTolerance && !_hasReachedTarget) {
      setState(() => _hasReachedTarget = true);
      _onTargetReached();
    } else if (distance > effectiveTolerance + 0.5 && _hasReachedTarget) {
      // Add hysteresis to prevent flickering when near boundary
      setState(() => _hasReachedTarget = false);
    }
  }

  void _onTargetReached() async {
    // Vibration feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
    }

    // Show notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎯 Target reached!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _useCurrentLocation() {
    final gpsService = context.read<GpsService>();
    if (gpsService.latitude != null && gpsService.longitude != null) {
      _targetLatController.text = gpsService.latitude!.toStringAsFixed(6);
      _targetLngController.text = gpsService.longitude!.toStringAsFixed(6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stakeout'),
        elevation: 0,
        actions: [
          if (_isActive)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: _stopStakeout,
              tooltip: 'Stop Stakeout',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stakeout Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Navigate precisely to target coordinates with audio/visual feedback.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Target coordinates input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target Coordinates', style: TextStyle(fontWeight: FontWeight.bold)),
                      OutlinedButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text('Use Current'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _targetLatController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            hintText: '28.6139',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: !_isActive,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _targetLngController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            hintText: '77.2090',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          enabled: !_isActive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _toleranceController,
                    decoration: const InputDecoration(
                      labelText: 'Tolerance (meters)',
                      hintText: '0.5',
                      suffixText: 'm',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isActive,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Start/Stop button
            if (!_isActive) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startStakeout,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Stakeout'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Stakeout Active',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],

            // Navigation display
            if (_isActive && _targetLat != null && _targetLng != null)
              Consumer2<GpsService, CompassProvider>(
                builder: (context, gpsService, compass, _) {
                  final currentLat = gpsService.latitude;
                  final currentLng = gpsService.longitude;

                  if (currentLat == null || currentLng == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final distance = GeoUtils.calculateDistance(currentLat, currentLng, _targetLat!, _targetLng!);
                  final bearing = GeoUtils.calculateBearing(currentLat, currentLng, _targetLat!, _targetLng!);

                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _hasReachedTarget ? _pulseAnimation.value : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _hasReachedTarget ? Colors.green[800] : Colors.blue[900],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _hasReachedTarget ? Colors.greenAccent : Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _hasReachedTarget ? Icons.check_circle : Icons.navigation,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _hasReachedTarget ? 'TARGET REACHED!' : 'Navigate to Target',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _navInfo('Distance', '${distance.toStringAsFixed(2)} m', Icons.straighten),
                                    Container(width: 1, height: 40, color: Colors.white30),
                                    _navInfo('Bearing', '${bearing.toStringAsFixed(1)}°', Icons.explore),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: math.max(0, 1 - (distance / 100)), // Show progress for first 100m
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _hasReachedTarget ? Colors.greenAccent : Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Within tolerance: ${distance <= _tolerance ? 'YES' : 'NO'}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

            // Instructions
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to Use Stakeout',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  _instructionItem('1. Enter target coordinates or use current location'),
                  _instructionItem('2. Set tolerance (how close you need to be)'),
                  _instructionItem('3. Start stakeout and follow the bearing'),
                  _instructionItem('4. App will vibrate and notify when target is reached'),
                  _instructionItem('5. Green indicator shows when within tolerance'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _instructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}