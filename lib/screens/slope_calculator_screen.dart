import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/geo_utils.dart';

class SlopeCalculatorScreen extends StatefulWidget {
  const SlopeCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<SlopeCalculatorScreen> createState() => _SlopeCalculatorScreenState();
}

class _SlopeCalculatorScreenState extends State<SlopeCalculatorScreen> {
  final _lat1Controller = TextEditingController();
  final _lng1Controller = TextEditingController();
  final _alt1Controller = TextEditingController();
  final _lat2Controller = TextEditingController();
  final _lng2Controller = TextEditingController();
  final _alt2Controller = TextEditingController();

  double? _slopePercent;
  double? _slopeAngle;
  double? _horizontalDistance;
  double? _verticalDistance;
  double? _directDistance;
  String _slopeDirection = '--';

  void _calculate() {
    final lat1 = double.tryParse(_lat1Controller.text);
    final lng1 = double.tryParse(_lng1Controller.text);
    final alt1 = double.tryParse(_alt1Controller.text);
    final lat2 = double.tryParse(_lat2Controller.text);
    final lng2 = double.tryParse(_lng2Controller.text);
    final alt2 = double.tryParse(_alt2Controller.text);

    if (lat1 == null || lng1 == null || alt1 == null ||
        lat2 == null || lng2 == null || alt2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields with valid numbers')),
      );
      return;
    }

    final horizontalDist = GeoUtils.calculateDistance(lat1, lng1, lat2, lng2);
    final vertDist = alt2 - alt1;

    double? slopePercent;
    double? slopeAngle;

    if (horizontalDist > 0) {
      slopePercent = (vertDist / horizontalDist) * 100;
      slopeAngle = (vertDist / horizontalDist).abs() * (180 / 3.14159);
    }

    final directDist = sqrt(horizontalDist * horizontalDist + vertDist * vertDist);

    String direction;
    if (vertDist > 0.5) {
      direction = 'Uphill ▲';
    } else if (vertDist < -0.5) {
      direction = 'Downhill ▼';
    } else {
      direction = 'Flat ─';
    }

    setState(() {
      _horizontalDistance = horizontalDist;
      _verticalDistance = vertDist;
      _directDistance = directDist > 0 ? directDist : null;
      _slopePercent = slopePercent;
      _slopeAngle = slopeAngle;
      _slopeDirection = direction;
    });
  }

  void _clear() {
    _lat1Controller.clear();
    _lng1Controller.clear();
    _alt1Controller.clear();
    _lat2Controller.clear();
    _lng2Controller.clear();
    _alt2Controller.clear();
    setState(() {
      _slopePercent = null;
      _slopeAngle = null;
      _horizontalDistance = null;
      _verticalDistance = null;
      _directDistance = null;
      _slopeDirection = '--';
    });
  }

  @override
  void dispose() {
    _lat1Controller.dispose();
    _lng1Controller.dispose();
    _alt1Controller.dispose();
    _lat2Controller.dispose();
    _lng2Controller.dispose();
    _alt2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slope Calculator'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.clear_all), onPressed: _clear),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPointCard('Point A (Top/Start)', _lat1Controller, _lng1Controller, _alt1Controller, Colors.blue),
            const SizedBox(height: 12),
            _buildPointCard('Point B (Bottom/End)', _lat2Controller, _lng2Controller, _alt2Controller, Colors.orange),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate),
              label: const Text('Calculate Slope'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            if (_slopePercent != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointCard(String title, TextEditingController lat, TextEditingController lng, TextEditingController alt, Color color) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(lat, 'Latitude', '28.6139')),
                const SizedBox(width: 8),
                Expanded(child: _buildTextField(lng, 'Longitude', '77.2090')),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(alt, 'Altitude (m)', '216'),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildResults() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_slopeDirection, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _resultItem('Slope', '${_slopePercent!.toStringAsFixed(2)}%', Colors.cyan),
                _resultItem('Angle', '${_slopeAngle!.toStringAsFixed(1)}°', Colors.orange),
                _resultItem('Rise', '${_verticalDistance!.toStringAsFixed(1)}m', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _resultItem('Run', GeoUtils.formatDistance(_horizontalDistance!), Colors.blue),
                _resultItem('Grade', _getGrade(_slopePercent!.abs()), _getGradeColor(_slopePercent!.abs())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  String _getGrade(double percent) {
    if (percent < 2) return 'Flat';
    if (percent < 5) return 'Gentle';
    if (percent < 10) return 'Moderate';
    if (percent < 20) return 'Steep';
    if (percent < 35) return 'Very Steep';
    return 'Extreme';
  }

  Color _getGradeColor(double percent) {
    if (percent < 5) return Colors.green;
    if (percent < 15) return Colors.orange;
    return Colors.red;
  }
}
