import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _sensorsRef = FirebaseDatabase.instance.ref('sensors');
  final int _maxDataPoints = 20;
  
  // Stream for the latest sensor data
  Stream<SensorData> getLatestSensorData() {
    return _sensorsRef
        .orderByKey()
        .limitToLast(1)
        .onValue
        .map((event) {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          final String key = data.keys.first.toString();
          return SensorData.fromMap(data[key], key);
        });
  }

  // Get the last 20 data points for the chart
  Stream<List<SensorData>> getLast20SensorData() {
    return _sensorsRef
        .orderByKey()
        .limitToLast(_maxDataPoints)
        .onValue
        .map((event) {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          List<SensorData> sensorDataList = [];
          
          // Sort keys in ascending order to ensure chronological order
          List<String> sortedKeys = data.keys.map((key) => key.toString()).toList()
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          
          for (var key in sortedKeys) {
            sensorDataList.add(SensorData.fromMap(data[key], key));
          }
          
          return sensorDataList;
        });
  }
}
