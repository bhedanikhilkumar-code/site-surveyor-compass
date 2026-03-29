// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:site_surveyor_compass/main.dart';
import 'package:site_surveyor_compass/services/waypoint_service.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    final waypointService = WaypointService();
    await waypointService.initialize();

    // Build our app and trigger a frame.
    await tester.pumpWidget(SiteSurveyorCompassApp(waypointService: waypointService));

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
