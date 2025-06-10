import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

enum MetricType {
  rendement,
  efficacite,
  irradiation,
}

class MetricChart extends StatelessWidget {
  final List<SensorData> sensorDataList;
  final MetricType metricType;

  const MetricChart({
    Key? key,
    required this.sensorDataList,
    required this.metricType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter out data points that don't have the required metric
    final filteredData = sensorDataList.where((data) {
      switch (metricType) {
        case MetricType.rendement:
          return data.rendement != null;
        case MetricType.efficacite:
          return data.efficacite != null;
        case MetricType.irradiation:
          return data.irradiation != null;
      }
    }).toList();

    if (filteredData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No data available for this metric',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(_getMetricColor(), _getMetricLabel(), context),
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
                    'Time',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Show only a few timestamps for readability
                      if (value.toInt() % 4 == 0 &&
                          value.toInt() < filteredData.length) {
                        // Format timestamp for display
                        final index = value.toInt();
                        if (index >= 0 && index < filteredData.length) {
                          final timestamp = filteredData[index].timestamp;
                          // Just show the index for simplicity
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '$index',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                      }
                      return const SizedBox();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    _getMetricLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getMetricColor(),
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getMetricColor(),
                          ),
                        ),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                // Metric line
                LineChartBarData(
                  spots: List.generate(
                    filteredData.length,
                    (index) => FlSpot(
                      index.toDouble(),
                      _getMetricValue(filteredData[index]),
                    ),
                  ),
                  isCurved: true,
                  color: _getMetricColor(),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _getMetricColor().withOpacity(0.2),
                  ),
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

  Color _getMetricColor() {
    switch (metricType) {
      case MetricType.rendement:
        return Colors.purple;
      case MetricType.efficacite:
        return Colors.green;
      case MetricType.irradiation:
        return Colors.amber;
    }
  }

  String _getMetricLabel() {
    switch (metricType) {
      case MetricType.rendement:
        return 'Rendement (%)';
      case MetricType.efficacite:
        return 'Efficacité (%)';
      case MetricType.irradiation:
        return 'Irradiation (W/m²)';
    }
  }

  double _getMetricValue(SensorData data) {
    switch (metricType) {
      case MetricType.rendement:
        return data.rendement ?? 0;
      case MetricType.efficacite:
        return data.efficacite ?? 0;
      case MetricType.irradiation:
        return data.irradiation ?? 0;
    }
  }
}
