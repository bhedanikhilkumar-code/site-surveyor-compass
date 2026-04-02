import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Information'),
        elevation: 0,
      ),
      body: Consumer<GpsService>(
        builder: (context, gps, _) {
          final location = gps.getLocationString();
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud, size: 100, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  'Weather at $location',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Weather data not available yet.\nFeature under development.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}