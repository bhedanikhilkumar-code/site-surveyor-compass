import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/compass_provider.dart';
import '../services/gps_service.dart';
import '../widgets/compass_dial.dart';
import 'waypoint_manager_screen.dart';
import 'level_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showTrueBearing = true;
  String _currentTime = '';
  String _currentDate = '';
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final gpsService = context.read<GpsService>();
      await gpsService.getInitialPosition();
      await gpsService.startLocationUpdates(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalMs: 1000,
        distanceFilterMeters: 5,
      );
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate = '${now.day.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60), // Space for indicators

                const SizedBox(height: 24),

                // COMPASS SECTION - Only this part rebuilds on bearing change
                Selector<CompassProvider, double>(
                  selector: (_, provider) => _showTrueBearing ? provider.trueBearing : provider.bearing,
                  builder: (context, bearing, _) {
                    return Column(
                      children: [
                        Center(
                          child: CompassDial(bearing: bearing),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.read<CompassProvider>().getCardinalDirection(bearing),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // GPS COORDINATES - Only rebuilds when GPS changes
                Consumer<GpsService>(
                  builder: (context, gpsService, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCoordinateColumn(
                              'NL',
                              gpsService.latitude != null
                                  ? _formatCoordinate(gpsService.latitude!.abs(), isLatitude: true) +
                                    (gpsService.latitude! >= 0 ? ' N' : ' S')
                                  : '--',
                            ),
                            _buildCoordinateColumn(
                              'EL',
                              gpsService.longitude != null
                                  ? _formatCoordinate(gpsService.longitude!.abs(), isLatitude: false) +
                                    (gpsService.longitude! >= 0 ? ' E' : ' W')
                                  : '--',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Address and GPS Info
                        if (gpsService.address != null)
                          Text(
                            gpsService.address!,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // GPS STATUS & NAV DATA - Rebuilds on compass changes
                Selector<CompassProvider, _NavData>(
                  selector: (_, p) => _NavData(
                    speed: p.speed,
                    accuracy: p.accuracy,
                    hasGpsLock: p.hasGpsLock,
                    declination: p.magneticDeclination,
                  ),
                  builder: (context, navData, child) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                size: 14,
                                color: navData.hasGpsLock ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                navData.accuracy > 0
                                    ? '${navData.accuracy.toStringAsFixed(0)}m accuracy'
                                    : 'No GPS lock',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: navData.hasGpsLock ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildNavDataColumn(
                                Icons.speed,
                                '${navData.speed.toStringAsFixed(1)}',
                                'km/h',
                                navData.hasGpsLock ? Colors.green : Colors.orange,
                              ),
                              _buildNavDataColumn(
                                Icons.gps_fixed,
                                navData.accuracy > 0
                                    ? '${navData.accuracy.toStringAsFixed(0)}'
                                    : '--',
                                'meters',
                                navData.hasGpsLock ? Colors.green : Colors.red,
                              ),
                              _buildNavDataColumn(
                                Icons.compass_calibration,
                                '${navData.declination.toStringAsFixed(1)}°',
                                'decl.',
                                Colors.cyan,
                              ),
                              child!, // altitude from GpsService
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  child: Consumer<GpsService>(
                    builder: (context, gpsService, _) => _buildNavDataColumn(
                      Icons.height,
                      gpsService.altitude != null
                          ? '${gpsService.altitude!.toStringAsFixed(0)}'
                          : '--',
                      'meters',
                      gpsService.altitude != null ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Time & Bearing Info Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavDataColumn(
                        Icons.access_time,
                        _currentTime,
                        _currentDate,
                        Colors.amber,
                      ),
                      Selector<CompassProvider, bool>(
                        selector: (_, p) => _showTrueBearing,
                        builder: (context, isTrue, _) => _buildNavDataColumn(
                          isTrue ? Icons.explore : Icons.compass_calibration,
                          isTrue ? 'TRUE' : 'MAG',
                          'north',
                          isTrue ? Colors.blue : Colors.red,
                        ),
                      ),
                      _buildNavDataColumn(Icons.wb_sunny, '06:30', 'sunrise', Colors.orange),
                      _buildNavDataColumn(Icons.brightness_2, '18:45', 'sunset', Colors.purple),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Elevation
                Consumer<GpsService>(
                  builder: (context, gpsService, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Elevation', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                      const SizedBox(width: 8),
                      Text(
                        gpsService.currentPosition?.altitude != null
                            ? '${gpsService.currentPosition!.altitude!.toStringAsFixed(1)} m'
                            : '--',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.info_outline, size: 12, color: Colors.red),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Bearing Type Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBearingToggle(
                        icon: Icons.compass_calibration,
                        label: 'Magnetic',
                        isActive: !_showTrueBearing,
                        onPressed: () => setState(() => _showTrueBearing = false),
                      ),
                      const SizedBox(width: 16),
                      _buildBearingToggle(
                        icon: Icons.explore,
                        label: 'True North',
                        isActive: _showTrueBearing,
                        onPressed: () => setState(() => _showTrueBearing = true),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Consumer<CompassProvider>(
                    builder: (context, provider, _) => Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.navigation,
                            label: 'Waypoints',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WaypointManagerScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.speed,
                            label: 'Speed: ${provider.speed.toStringAsFixed(1)} km/h',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Current Speed: ${provider.speed.toStringAsFixed(1)} m/s\n'
                                      'GPS Accuracy: ${provider.accuracy.toStringAsFixed(1)}m'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),

          // Status indicators at top
          Positioned(
            top: 20,
            left: 20,
            right: 60,
            child: Consumer<CompassProvider>(
              builder: (context, provider, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        provider.hasGpsLock ? Icons.gps_fixed : Icons.gps_off,
                        color: provider.hasGpsLock ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.hasGpsLock ? 'GPS' : 'No GPS',
                        style: TextStyle(
                          fontSize: 12,
                          color: provider.hasGpsLock ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (provider.accuracy > 0)
                    Text(
                      '${provider.accuracy.toStringAsFixed(0)}m',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),

          // Settings icon top right
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
              onPressed: () => _showSettingsBottomSheet(context),
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildNavDataColumn(IconData icon, String value, String unit, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 9,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatCoordinate(double coord, {required bool isLatitude}) {
    final absCoord = coord.abs();
    final degrees = absCoord.floor();
    final minutesFloat = (absCoord - degrees) * 60;
    final minutes = minutesFloat.floor();
    final seconds = ((minutesFloat - minutes) * 60).round();

    return '$degrees°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
            icon: Icons.explore,
            label: 'Compass',
            isActive: true,
            onPressed: () {}, // Already on compass
          ),
          _buildBottomNavItem(
            icon: Icons.aspect_ratio,
            label: 'Level',
            isActive: false,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LevelScreen(),
                ),
              );
            },
          ),
          _buildBottomNavItem(
            icon: Icons.map,
            label: 'Map',
            isActive: false,
            onPressed: () {
              // Placeholder for map screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Map feature coming soon!')),
              );
            },
          ),
          _buildBottomNavItem(
            icon: Icons.settings,
            label: 'Tools',
            isActive: false,
            onPressed: () {
              _showSettingsBottomSheet(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[500],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.white : Colors.grey[500],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildBearingToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? Colors.cyan.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isActive ? Colors.cyan : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.cyan : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.cyan : Colors.grey[400],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.grey[800]!,
              Colors.grey[850]!,
            ],
          ),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: Colors.cyan, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_location),
              title: const Text('Manage Waypoints'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaypointManagerScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavData {
  final double speed;
  final double accuracy;
  final bool hasGpsLock;
  final double declination;

  const _NavData({
    required this.speed,
    required this.accuracy,
    required this.hasGpsLock,
    required this.declination,
  });
}
