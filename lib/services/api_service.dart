import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import 'dart:developer' as developer;

class ApiService {
  // Update this URL to match your Flask server address
  final String apiUrl = 'http://10.0.2.2:5050/predict'; // Updated to port 5050

  /// Sends sensor data to the API and returns the processed data with additional metrics
  Future<SensorData> processSensorData(SensorData sensorData) async {
    try {
      developer.log(
        'Sending data to API: ${jsonEncode(sensorData.toApiJson())}',
      );
      developer.log('API URL: $apiUrl');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sensorData.toApiJson()),
      );

      developer.log('API Response Status: ${response.statusCode}');
      developer.log('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Return updated sensor data with all the metrics from the API
        return sensorData.withApiResponse(data);
      } else {
        throw Exception(
          'Failed to process sensor data: ${response.statusCode}, Response: ${response.body}',
        );
      }
    } catch (e) {
      developer.log('API Error: $e', error: e);
      throw Exception('Error sending data to API: $e');
    }
  }

  /// Legacy method for backward compatibility
  Future<int> predictLevel(SensorData sensorData) async {
    try {
      final updatedSensorData = await processSensorData(sensorData);
      return updatedSensorData.niveau ?? 0; // Default to 0 if niveau is null
    } catch (e) {
      developer.log('Error in predictLevel: $e', error: e);
      throw Exception('Error predicting level: $e');
    }
  }
}
