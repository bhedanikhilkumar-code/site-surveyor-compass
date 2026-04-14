import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class Hitem3dService {
  final String accessKey;
  final String secretKey;

  Hitem3dService(this.accessKey, this.secretKey);

  Future<String?> generate3DModel(List<LatLng> points, {String modelType = 'terrain'}) async {
    try {
      final url = Uri.parse('https://api.hitem3d.ai/generate'); // Placeholder URL

      final body = {
        'access_key': accessKey,
        'secret_key': secretKey,
        'points': points.map((p) => {'lat': p.latitude, 'lon': p.longitude}).toList(),
        'type': modelType,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['model_url'] as String; // Assuming the API returns a model URL
      } else {
        throw Exception('Failed to generate 3D model: ${response.statusCode}');
      }
    } catch (e) {
      return null;
    }
  }
}