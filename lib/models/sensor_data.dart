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
      timestamp: key,
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

  SensorData copyWith({int? niveau}) {
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
    );
  }
}
