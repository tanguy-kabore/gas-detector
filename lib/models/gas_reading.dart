class GasReading {
  final double value;
  final DateTime timestamp;

  GasReading({
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GasReading.fromJson(Map<String, dynamic> json) {
    return GasReading(
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
