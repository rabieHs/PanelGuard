import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import 'dart:developer' as developer;

class FirebaseService {
  final DatabaseReference _sensorsRef = FirebaseDatabase.instance.ref(
    'sensors',
  );
  final int _maxDataPoints = 20;
  final int _maxHistoricalDataPoints = 100; // For historical data charts

  // Stream for the latest sensor data
  Stream<SensorData> getLatestSensorData() {
    return _sensorsRef.orderByKey().limitToLast(1).onValue.map((event) {
      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      final String key = data.keys.first.toString();
      return SensorData.fromMap(data[key], key);
    });
  }

  // Get the last 20 data points for the chart
  Stream<List<SensorData>> getLast20SensorData() {
    return _sensorsRef.orderByKey().limitToLast(_maxDataPoints).onValue.map((
      event,
    ) {
      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;
      List<SensorData> sensorDataList = [];

      // Convert all data points to SensorData objects first
      for (var entry in data.entries) {
        String key = entry.key.toString();
        Map<dynamic, dynamic> value = entry.value as Map<dynamic, dynamic>;
        sensorDataList.add(SensorData.fromMap(value, key));
      }

      // Sort by timestamp (timepast field) to ensure chronological order
      sensorDataList.sort((a, b) {
        try {
          DateTime dateA = DateTime.parse(a.timestamp);
          DateTime dateB = DateTime.parse(b.timestamp);
          return dateA.compareTo(dateB);
        } catch (e) {
          // Fallback to string comparison if parsing fails
          return a.timestamp.compareTo(b.timestamp);
        }
      });

      return sensorDataList;
    });
  }

  /// Get historical data for time-based charts
  /// Returns a larger dataset for detailed time-series analysis
  Stream<List<SensorData>> getHistoricalSensorData() {
    return _sensorsRef
        .orderByKey()
        .limitToLast(_maxHistoricalDataPoints)
        .onValue
        .map((event) {
          try {
            final Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;
            List<SensorData> sensorDataList = [];

            // Convert all data points to SensorData objects first
            for (var entry in data.entries) {
              String key = entry.key.toString();
              Map<dynamic, dynamic> value =
                  entry.value as Map<dynamic, dynamic>;
              sensorDataList.add(SensorData.fromMap(value, key));
            }

            // Sort by timestamp (timepast field) to ensure chronological order
            sensorDataList.sort((a, b) {
              try {
                DateTime dateA = DateTime.parse(a.timestamp);
                DateTime dateB = DateTime.parse(b.timestamp);
                return dateA.compareTo(dateB);
              } catch (e) {
                // Fallback to string comparison if parsing fails
                return a.timestamp.compareTo(b.timestamp);
              }
            });

            developer.log(
              'Fetched ${sensorDataList.length} historical data points',
            );
            return sensorDataList;
          } catch (e) {
            developer.log('Error fetching historical data: $e', error: e);
            return <SensorData>[];
          }
        });
  }
}
