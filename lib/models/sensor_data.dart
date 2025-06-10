class SensorData {
  final double courant;
  final double humidity;
  final double luminosite;
  final double poussiere;
  final double puissance;
  final double temperature;
  final double tension;
  final String timestamp;
  final int? niveau; // Response from API

  // Additional metrics from API
  final double? rendement;
  final double? efficacite;
  final double? irradiation;

  SensorData({
    required this.courant,
    required this.humidity,
    required this.luminosite,
    required this.poussiere,
    required this.puissance,
    required this.temperature,
    required this.tension,
    required this.timestamp,
    this.niveau,
    this.rendement,
    this.efficacite,
    this.irradiation,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map, String key) {
    return SensorData(
      courant: (map['courant'] as num).toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
      luminosite: (map['luminosite'] as num).toDouble(),
      poussiere: (map['poussiere'] as num).toDouble(),
      puissance: (map['puissance'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      tension: (map['tension'] as num).toDouble(),
      timestamp:
          map['timepast'] as String? ??
          key, // Use timepast field or fallback to key
      niveau: null,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'courant': courant,
      'humidity': humidity,
      'luminosite': luminosite,
      'poussiere': poussiere,
      'puissance': puissance,
      'temperature': temperature,
      'tension': tension,
    };
  }

  SensorData copyWith({
    int? niveau,
    double? rendement,
    double? efficacite,
    double? irradiation,
  }) {
    return SensorData(
      courant: this.courant,
      humidity: this.humidity,
      luminosite: this.luminosite,
      poussiere: this.poussiere,
      puissance: this.puissance,
      temperature: this.temperature,
      tension: this.tension,
      timestamp: this.timestamp,
      niveau: niveau ?? this.niveau,
      rendement: rendement ?? this.rendement,
      efficacite: efficacite ?? this.efficacite,
      irradiation: irradiation ?? this.irradiation,
    );
  }

  /// Creates a new SensorData instance with API response data
  SensorData withApiResponse(Map<String, dynamic> apiResponse) {
    return copyWith(
      niveau: apiResponse['niveau'] as int?,
      rendement:
          apiResponse['rendement'] != null
              ? (apiResponse['rendement'] as num).toDouble()
              : null,
      efficacite:
          apiResponse['efficacite'] != null
              ? (apiResponse['efficacite'] as num).toDouble()
              : null,
      irradiation:
          apiResponse['irradiation'] != null
              ? (apiResponse['irradiation'] as num).toDouble()
              : null,
    );
  }
}
