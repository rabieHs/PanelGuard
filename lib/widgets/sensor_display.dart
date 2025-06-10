import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class SensorDisplay extends StatelessWidget {
  final SensorData sensorData;

  const SensorDisplay({Key? key, required this.sensorData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Sensor Data (ID: ${sensorData.timestamp})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSensorGrid(context),
            const SizedBox(height: 16),
            if (sensorData.niveau != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getLevelColor(sensorData.niveau!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLevelIcon(sensorData.niveau!),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Level: ${_getLevelLabel(sensorData.niveau!)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic sensor readings
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            _buildSensorItem(
              context,
              'Temperature',
              '${sensorData.temperature} °C',
              Icons.thermostat,
            ),
            _buildSensorItem(
              context,
              'Humidity',
              '${sensorData.humidity} %',
              Icons.water_drop,
            ),
            _buildSensorItem(
              context,
              'Luminosity',
              '${sensorData.luminosite.toStringAsFixed(2)} lux',
              Icons.light_mode,
            ),
            _buildSensorItem(
              context,
              'Dust',
              '${sensorData.poussiere.toStringAsFixed(2)} µg/m³',
              Icons.air,
            ),
            _buildSensorItem(
              context,
              'Current',
              '${sensorData.courant} A',
              Icons.electric_bolt,
            ),
            _buildSensorItem(
              context,
              'Voltage',
              '${sensorData.tension} V',
              Icons.bolt,
            ),
            _buildSensorItem(
              context,
              'Power',
              '${sensorData.puissance.toStringAsFixed(2)} W',
              Icons.power,
            ),
          ],
        ),

        // Additional metrics section
        if (sensorData.rendement != null ||
            sensorData.efficacite != null ||
            sensorData.irradiation != null) ...[
          const SizedBox(height: 16),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            children: [
              if (sensorData.rendement != null)
                _buildSensorItem(
                  context,
                  'Rendement',
                  '${sensorData.rendement!.toStringAsFixed(2)} %',
                  Icons.trending_up,
                ),
              if (sensorData.efficacite != null)
                _buildSensorItem(
                  context,
                  'Efficacité',
                  '${sensorData.efficacite!.toStringAsFixed(2)} %',
                  Icons.speed,
                ),
              if (sensorData.irradiation != null)
                _buildSensorItem(
                  context,
                  'Irradiation',
                  '${sensorData.irradiation!.toStringAsFixed(2)} W/m²',
                  Icons.wb_sunny,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSensorItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12)),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getLevelLabel(int level) {
    switch (level) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  IconData _getLevelIcon(int level) {
    switch (level) {
      case 0:
        return Icons.check_circle;
      case 1:
        return Icons.warning;
      case 2:
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}
