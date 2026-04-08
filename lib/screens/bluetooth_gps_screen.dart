import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

class BluetoothGpsScreen extends StatefulWidget {
  const BluetoothGpsScreen({super.key});

  @override
  State<BluetoothGpsScreen> createState() => _BluetoothGpsScreenState();
}

class _BluetoothGpsScreenState extends State<BluetoothGpsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth GPS'),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth_disabled, size: 80, color: Colors.white38),
              const SizedBox(height: 24),
              const Text(
                'Bluetooth GPS',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Connect external Bluetooth GPS devices for higher accuracy positioning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add flutter_blue_plus to pubspec.yaml to enable this feature')),
                  );
                },
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Scan for Devices'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 32),
              GlassContainer(
                blur: 10,
                opacity: 0.1,
                borderRadius: BorderRadius.circular(12),
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supported Devices',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDeviceInfo('Garmin GPS', 'Bluetooth-enabled models'),
                    _buildDeviceInfo('Trimble GPS', 'Bluetooth receivers'),
                    _buildDeviceInfo('Leica GPS', 'Smart antennas'),
                    _buildDeviceInfo('Any NMEA-compatible', 'Bluetooth GPS receiver'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(String name, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text('$name - $desc', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
   }
}

