import 'package:flutter_test/flutter_test.dart';
import 'package:aido_sensor_app/models/sensor_data.dart';

void main() {
  group('SensorData', () {
    test('should create a SensorData instance from a map', () {
      // Arrange
      final Map<dynamic, dynamic> map = {
        'courant': 52.9,
        'humidity': 42.4,
        'luminosite': 54612.49609,
        'poussiere': 524.21875,
        'puissance': 676.90839,
        'temperature': 26.7,
        'tension': 12.796,
      };
      const String key = '1967';

      // Act
      final sensorData = SensorData.fromMap(map, key);

      // Assert
      expect(sensorData.courant, 52.9);
      expect(sensorData.humidity, 42.4);
      expect(sensorData.luminosite, 54612.49609);
      expect(sensorData.poussiere, 524.21875);
      expect(sensorData.puissance, 676.90839);
      expect(sensorData.temperature, 26.7);
      expect(sensorData.tension, 12.796);
      expect(sensorData.timestamp, '1967');
      expect(sensorData.niveau, null);
    });

    test('should convert SensorData to API JSON format', () {
      // Arrange
      final sensorData = SensorData(
        courant: 52.9,
        humidity: 42.4,
        luminosite: 54612.49609,
        poussiere: 524.21875,
        puissance: 676.90839,
        temperature: 26.7,
        tension: 12.796,
        timestamp: '1967',
      );

      // Act
      final json = sensorData.toApiJson();

      // Assert
      expect(json['courant'], 52.9);
      expect(json['humidity'], 42.4);
      expect(json['luminosite'], 54612.49609);
      expect(json['poussiere'], 524.21875);
      expect(json['puissance'], 676.90839);
      expect(json['temperature'], 26.7);
      expect(json['tension'], 12.796);
      expect(json.containsKey('timestamp'), false);
      expect(json.containsKey('niveau'), false);
    });

    test('should create a copy with niveau', () {
      // Arrange
      final sensorData = SensorData(
        courant: 52.9,
        humidity: 42.4,
        luminosite: 54612.49609,
        poussiere: 524.21875,
        puissance: 676.90839,
        temperature: 26.7,
        tension: 12.796,
        timestamp: '1967',
      );

      // Act
      final copy = sensorData.copyWith(niveau: 2);

      // Assert
      expect(copy.courant, 52.9);
      expect(copy.humidity, 42.4);
      expect(copy.luminosite, 54612.49609);
      expect(copy.poussiere, 524.21875);
      expect(copy.puissance, 676.90839);
      expect(copy.temperature, 26.7);
      expect(copy.tension, 12.796);
      expect(copy.timestamp, '1967');
      expect(copy.niveau, 2);
    });
  });
}
