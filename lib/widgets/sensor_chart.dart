import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class SensorChart extends StatelessWidget {
  final List<SensorData> sensorDataList;

  const SensorChart({Key? key, required this.sensorDataList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.blue, 'Luminosity (lux/1000)', context),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.orange, 'Power (W)', context),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Chart
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Data Points',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Show only a few timestamps for readability
                      if (value.toInt() % 4 == 0 &&
                          value.toInt() < sensorDataList.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Luminosity (lux/1000)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                rightTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Power (W)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                          ),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                // Luminosity line (left axis)
                LineChartBarData(
                  spots: List.generate(
                    sensorDataList.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      sensorDataList[index].luminosite /
                          1000, // Scale down for better visualization
                    ),
                  ),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                // Puissance line (right axis)
                LineChartBarData(
                  spots: List.generate(
                    sensorDataList.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      sensorDataList[index].puissance,
                    ),
                  ),
                  isCurved: true,
                  color: Colors.orange,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
