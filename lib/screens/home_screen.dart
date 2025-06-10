import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../widgets/sensor_chart.dart';
import '../widgets/sensor_display.dart';
import '../widgets/metric_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();

  SensorData? _latestSensorData;
  List<SensorData> _chartData = [];
  List<SensorData> _historicalData = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Current selected metric for the chart
  MetricType _selectedMetricType = MetricType.rendement;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    // Listen for the latest sensor data
    _firebaseService.getLatestSensorData().listen(
      (sensorData) async {
        try {
          // Send data to API and get processed data with additional metrics
          final processedData = await _apiService.processSensorData(sensorData);

          setState(() {
            _latestSensorData = processedData;
            _isLoading = false;
            _errorMessage = null;
          });

          developer.log(
            'Received processed data: Rendement=${processedData.rendement}, '
            'Efficacité=${processedData.efficacite}, '
            'Irradiation=${processedData.irradiation}',
          );
        } catch (e) {
          setState(() {
            _latestSensorData = sensorData;
            _isLoading = false;
            _errorMessage = 'Failed to process sensor data: $e';
          });
          developer.log('Error processing sensor data: $e', error: e);
        }
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error fetching latest data: $error';
        });
        developer.log('Error fetching latest data: $error', error: error);
      },
    );

    // Listen for chart data (luminosity vs power)
    _firebaseService.getLast20SensorData().listen(
      (dataList) {
        setState(() {
          _chartData = dataList;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Error fetching chart data: $error';
        });
        developer.log('Error fetching chart data: $error', error: error);
      },
    );

    // Listen for historical data for metrics charts
    _firebaseService.getHistoricalSensorData().listen(
      (dataList) async {
        // Process each data point to get metrics from API
        List<SensorData> processedDataList = [];

        try {
          // Process the most recent data points first (last 10)
          final recentData =
              dataList.length > 10
                  ? dataList.sublist(dataList.length - 10)
                  : dataList;

          for (var data in recentData) {
            try {
              final processedData = await _apiService.processSensorData(data);
              processedDataList.add(processedData);
            } catch (e) {
              // If processing fails, add the original data
              processedDataList.add(data);
              developer.log(
                'Error processing historical data point: $e',
                error: e,
              );
            }
          }

          setState(() {
            _historicalData = processedDataList;
          });

          developer.log(
            'Processed ${processedDataList.length} historical data points',
          );
        } catch (e) {
          developer.log('Error processing historical data: $e', error: e);
        }
      },
      onError: (error) {
        developer.log('Error fetching historical data: $error', error: error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AIDO Sensor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _setupStreams();
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('About AIDO Sensor App'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This app displays real-time sensor data from Firebase.',
                          ),
                          SizedBox(height: 8),
                          Text('• Reads latest sensor values'),
                          Text(
                            '• Sends data to API for level prediction (Low/Medium/High)',
                          ),
                          Text('• Displays luminosity vs power chart'),
                          SizedBox(height: 8),
                          Text(
                            'Data is updated in real-time as new values are added to the database.',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _setupStreams();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  _setupStreams();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_latestSensorData != null)
                        SensorDisplay(sensorData: _latestSensorData!),
                      // Original chart section (Luminosity vs Power)
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Luminosity vs Power (Last 20 Readings)',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              if (_chartData.isNotEmpty)
                                SensorChart(sensorDataList: _chartData)
                              else
                                const Center(
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
                                          'No chart data available',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Performance metrics chart section
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Performance Metrics',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                    ),
                                  ),
                                  // Dropdown to select metric type
                                  DropdownButton<MetricType>(
                                    value: _selectedMetricType,
                                    onChanged: (MetricType? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedMetricType = newValue;
                                        });
                                      }
                                    },
                                    items: [
                                      DropdownMenuItem(
                                        value: MetricType.rendement,
                                        child: Text('Rendement'),
                                      ),
                                      DropdownMenuItem(
                                        value: MetricType.efficacite,
                                        child: Text('Efficacité'),
                                      ),
                                      DropdownMenuItem(
                                        value: MetricType.irradiation,
                                        child: Text('Irradiation'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (_historicalData.isNotEmpty)
                                MetricChart(
                                  sensorDataList: _historicalData,
                                  metricType: _selectedMetricType,
                                )
                              else
                                const Center(
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
                                          'No metrics data available',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Add some space at the bottom
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }
}
