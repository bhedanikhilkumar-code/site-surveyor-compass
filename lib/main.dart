import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'providers/compass_provider.dart';
import 'models/waypoint_model.dart';
import 'services/gps_service.dart';
import 'services/waypoint_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request required permissions upfront
  await _requestPermissions();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(WaypointAdapter());
  
  // Initialize waypoint service
  final waypointService = WaypointService();
  await waypointService.initialize();

  // Initialize compass provider
  final compassProvider = CompassProvider();

  runApp(SiteSurveyorCompassApp(
    waypointService: waypointService,
    compassProvider: compassProvider,
  ));
}

Future<void> _requestPermissions() async {
  final statuses = await [
    Permission.location,
    Permission.sensors,
  ].request();

  if (statuses[Permission.location]!.isDenied) {
    print('Location permission denied');
  }
  if (statuses[Permission.sensors]!.isDenied) {
    print('Sensor permission denied');
  }
}

class SiteSurveyorCompassApp extends StatelessWidget {
  final WaypointService waypointService;
  final CompassProvider compassProvider;

  const SiteSurveyorCompassApp({
    Key? key,
    required this.waypointService,
    required this.compassProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: compassProvider),
        ChangeNotifierProvider(
          create: (context) {
            final gpsService = GpsService();
            gpsService.setCompassProvider(compassProvider);
            return gpsService;
          },
        ),
        Provider<WaypointService>(create: (_) => waypointService),
      ],
      child: MaterialApp(
        title: 'Site Surveyor Compass',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
