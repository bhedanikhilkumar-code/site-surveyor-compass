import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    title: 'Site Surveyor Compass',
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}