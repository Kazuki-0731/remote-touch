/// Application settings
class AppSettings {
  final double sensitivity;
  final Duration idleTimeout;
  final bool autoReconnect;
  final int maxReconnectAttempts;

  AppSettings({
    this.sensitivity = 1.0,
    this.idleTimeout = const Duration(seconds: 60),
    this.autoReconnect = true,
    this.maxReconnectAttempts = 10,
  });

  Map<String, dynamic> toJson() {
    return {
      'sensitivity': sensitivity,
      'idleTimeout': idleTimeout.inSeconds,
      'autoReconnect': autoReconnect,
      'maxReconnectAttempts': maxReconnectAttempts,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 1.0,
      idleTimeout: Duration(seconds: json['idleTimeout'] as int? ?? 60),
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      maxReconnectAttempts: json['maxReconnectAttempts'] as int? ?? 10,
    );
  }

  AppSettings copyWith({
    double? sensitivity,
    Duration? idleTimeout,
    bool? autoReconnect,
    int? maxReconnectAttempts,
  }) {
    return AppSettings(
      sensitivity: sensitivity ?? this.sensitivity,
      idleTimeout: idleTimeout ?? this.idleTimeout,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
    );
  }

  @override
  String toString() {
    return 'AppSettings(sensitivity: $sensitivity, idleTimeout: $idleTimeout, autoReconnect: $autoReconnect, maxReconnectAttempts: $maxReconnectAttempts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.sensitivity == sensitivity &&
        other.idleTimeout == idleTimeout &&
        other.autoReconnect == autoReconnect &&
        other.maxReconnectAttempts == maxReconnectAttempts;
  }

  @override
  int get hashCode {
    return sensitivity.hashCode ^
        idleTimeout.hashCode ^
        autoReconnect.hashCode ^
        maxReconnectAttempts.hashCode;
  }
}
