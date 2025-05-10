import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class ApiService {
  final String apiUrl = 'http://192.168.2.108:3000/predict';

  Future<int> predictLevel(SensorData sensorData) async {
    try {
      print('Sending data to API: ${jsonEncode(sensorData.toApiJson())}');
      print('API URL: $apiUrl');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sensorData.toApiJson()),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['niveau'] as int; // API still returns 'niveau' key
      } else {
        throw Exception(
          'Failed to predict level: ${response.statusCode}, Response: ${response.body}',
        );
      }
    } catch (e) {
      print('API Error: $e');
      throw Exception('Error sending data to API: $e');
    }
  }
}
