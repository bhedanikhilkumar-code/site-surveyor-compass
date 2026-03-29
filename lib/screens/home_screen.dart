import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compass_provider.dart';
import '../services/gps_service.dart';
import '../services/waypoint_service.dart';
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gpsService = context.read<GpsService>();
      gpsService.getInitialPosition();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Consumer3<CompassProvider, GpsService, WaypointService>(
        builder: (context, compassProvider, gpsService, waypointService, _) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 60), // Space for indicators

                    const SizedBox(height: 24),

                    // COMPASS DIAL - Rotating dial with tick marks, numbers, cardinal directions
                    Center(
                      child: CompassDial(
                        bearing: compassProvider.bearing,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Direction Text (e.g., 'South', 'North', etc.)
                    Text(
                      compassProvider.getCardinalDirection(compassProvider.bearing),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontFamily: 'sans-serif',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // GPS Info Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Coordinates
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
                          Column(
                            children: [
                              if (gpsService.address != null)
                                Text(
                                  gpsService.address!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              // GPS Accuracy
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.gps_fixed,
                                    size: 14,
                                    color: compassProvider.hasGpsLock ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    gpsService.accuracy != null
                                        ? '${gpsService.accuracy!.toStringAsFixed(0)}m accuracy'
                                        : 'No GPS lock',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: compassProvider.hasGpsLock ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Navigation Data Grid (4 columns)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Speed
                              _buildNavDataColumn(
                                Icons.speed,
                                '${compassProvider.speed.toStringAsFixed(1)}',
                                'km/h',
                                compassProvider.hasGpsLock ? Colors.green : Colors.orange,
                              ),
                              // Accuracy
                              _buildNavDataColumn(
                                Icons.gps_fixed,
                                compassProvider.accuracy > 0
                                    ? '${compassProvider.accuracy.toStringAsFixed(0)}'
                                    : '--',
                                'meters',
                                compassProvider.hasGpsLock ? Colors.green : Colors.red,
                              ),
                              // Declination
                              _buildNavDataColumn(
                                Icons.compass_calibration,
                                '${compassProvider.magneticDeclination.toStringAsFixed(1)}°',
                                'decl.',
                                Colors.cyan,
                              ),
                              // Altitude
                              _buildNavDataColumn(
                                Icons.height,
                                gpsService.altitude != null
                                    ? '${gpsService.altitude!.toStringAsFixed(0)}'
                                    : '--',
                                'meters',
                                gpsService.altitude != null ? Colors.blue : Colors.grey,
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Additional Navigation Info (4 more items for comprehensive display)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Time
                              _buildNavDataColumn(
                                Icons.access_time,
                                DateTime.now().toString().substring(11, 16), // HH:MM
                                DateTime.now().toString().substring(8, 10), // Day
                                Colors.amber,
                              ),
                              // Bearing Format
                              _buildNavDataColumn(
                                _showTrueBearing ? Icons.explore : Icons.compass_calibration,
                                _showTrueBearing ? 'TRUE' : 'MAG',
                                'north',
                                _showTrueBearing ? Colors.blue : Colors.red,
                              ),
                              // Sunrise
                              _buildNavDataColumn(
                                Icons.wb_sunny,
                                '06:30', // Placeholder - would need location-based calculation
                                'sunrise',
                                Colors.orange,
                              ),
                              // Sunset
                              _buildNavDataColumn(
                                Icons.brightness_2,
                                '18:45', // Placeholder - would need location-based calculation
                                'sunset',
                                Colors.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Elevation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Elevation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          gpsService.currentPosition?.altitude != null
                              ? '${gpsService.currentPosition!.altitude!.toStringAsFixed(1)} m'
                              : '--',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: Colors.red,
                        ),
                      ],
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
                        onPressed: () {
                          setState(() => _showTrueBearing = false);
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildBearingToggle(
                        icon: Icons.explore,
                        label: 'True North',
                        isActive: _showTrueBearing,
                        onPressed: () {
                          setState(() => _showTrueBearing = true);
                        },
                      ),
                    ],
                  ),
                ),

                    const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.navigation,
                          label: 'Waypoints',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const WaypointManagerScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.speed,
                          label: 'Speed: ${compassProvider.speed.toStringAsFixed(1)} km/h',
                          onPressed: () {
                            // Speed is already displayed, maybe show detailed speed info
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Current Speed: ${compassProvider.speed.toStringAsFixed(1)} m/s\n'
                                  'GPS Accuracy: ${compassProvider.accuracy.toStringAsFixed(1)}m'
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),

              // Top indicators
              Positioned(
                top: 20,
                left: 20,
                right: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // GPS Status
                    Row(
                      children: [
                        Icon(
                          compassProvider.hasGpsLock ? Icons.gps_fixed : Icons.gps_off,
                          color: compassProvider.hasGpsLock ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          compassProvider.hasGpsLock ? 'GPS' : 'No GPS',
                          style: TextStyle(
                            fontSize: 12,
                            color: compassProvider.hasGpsLock ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    // Accuracy
                    if (compassProvider.accuracy > 0)
                      Text(
                        '${compassProvider.accuracy.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),

              // Settings icon top right
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => _showSettingsBottomSheet(context),
                ),
              ),

              // Bottom Navigation (4 tabs)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomNavigation(),
              ),
            ],
          );
        },
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
