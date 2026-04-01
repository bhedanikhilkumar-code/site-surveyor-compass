import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CoordinateConverterScreen extends StatefulWidget {
  const CoordinateConverterScreen({Key? key}) : super(key: key);

  @override
  State<CoordinateConverterScreen> createState() => _CoordinateConverterScreenState();
}

class _CoordinateConverterScreenState extends State<CoordinateConverterScreen> {
  final _latController = TextEditingController(text: '28.6139');
  final _lngController = TextEditingController(text: '77.2090');

  String _dd = '';
  String _dms = '';
  String _utm = '';

  @override
  void initState() {
    super.initState();
    _convert();
  }

  void _convert() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat == null || lng == null) return;

    setState(() {
      _dd = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      _dms = _toDms(lat, isLat: true) + '\n' + _toDms(lng, isLat: false);
      _utm = _toUtm(lat, lng);
    });
  }

  String _toDms(double coord, {required bool isLat}) {
    final abs = coord.abs();
    final d = abs.floor();
    final mFloat = (abs - d) * 60;
    final m = mFloat.floor();
    final s = ((mFloat - m) * 60).toStringAsFixed(2);
    final dir = isLat ? (coord >= 0 ? 'N' : 'S') : (coord >= 0 ? 'E' : 'W');
    return "$d°$m'$s\"$dir";
  }

  String _toUtm(double lat, double lng) {
    final zone = ((lng + 180) / 6).floor() + 1;
    final letter = lat >= 0 ? 'N' : 'S';

    final a = 6378137.0;
    final f = 1 / 298.257223563;
    final k0 = 0.9996;
    final e = sqrt(2 * f - f * f);
    final e2 = e * e / (1 - e * e);

    final latRad = lat * pi / 180;
    final lngRad = lng * pi / 180;
    final lngOrigin = (zone - 1) * 6 - 180 + 3;
    final lngOriginRad = lngOrigin * pi / 180;

    final N = a / sqrt(1 - e * e * sin(latRad) * sin(latRad));
    final T = tan(latRad) * tan(latRad);
    final C = e2 * cos(latRad) * cos(latRad);
    final A = cos(latRad) * (lngRad - lngOriginRad);

    final M = a * (
      (1 - e * e / 4 - 3 * e * e * e * e / 64) * latRad -
      (3 * e * e / 8 + 3 * e * e * e * e / 32) * sin(2 * latRad) +
      (15 * e * e * e * e / 256) * sin(4 * latRad)
    );

    final easting = k0 * N * (A + (1 - T + C) * A * A * A / 6) + 500000;
    final northing = k0 * (M + N * tan(latRad) * (A * A / 2 + (5 - T + 9 * C) * A * A * A * A / 24));

    return 'Zone: $zone$letter\nEasting: ${easting.toStringAsFixed(2)}\nNorthing: ${northing.toStringAsFixed(2)}';
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coordinate Converter'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter Coordinates', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildField(_latController, 'Latitude', '28.6139')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildField(_lngController, 'Longitude', '77.2090')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _convert,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Convert'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildResultCard('Decimal Degrees (DD)', _dd, Colors.blue),
            _buildResultCard('DMS (Degrees Minutes Seconds)', _dms, Colors.green),
            _buildResultCard('UTM (Universal Transverse Mercator)', _utm, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, String hint) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildResultCard(String title, String value, Color color) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[500]),
                  onPressed: () => _copy(value),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}
