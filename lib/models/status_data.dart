/// Status data sent from macOS to iOS
class StatusData {
  final int batteryLevel;
  final DateTime timestamp;
  final int connectionQuality;

  StatusData({
    required this.batteryLevel,
    required this.timestamp,
    required this.connectionQuality,
  });

  Map<String, dynamic> toJson() {
    return {
      'batteryLevel': batteryLevel,
      'timestamp': timestamp.toIso8601String(),
      'connectionQuality': connectionQuality,
    };
  }

  factory StatusData.fromJson(Map<String, dynamic> json) {
    return StatusData(
      batteryLevel: json['batteryLevel'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      connectionQuality: json['connectionQuality'] as int,
    );
  }

  @override
  String toString() {
    return 'StatusData(batteryLevel: $batteryLevel, timestamp: $timestamp, connectionQuality: $connectionQuality)';
  }
}
