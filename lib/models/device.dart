/// Represents a macOS device that can be connected to
class Device {
  final String id;
  final String name;
  final String peripheralUUID;
  final DateTime lastConnected;
  final bool isPaired;

  Device({
    required this.id,
    required this.name,
    required this.peripheralUUID,
    required this.lastConnected,
    required this.isPaired,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'peripheralUUID': peripheralUUID,
      'lastConnected': lastConnected.toIso8601String(),
      'isPaired': isPaired,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      peripheralUUID: json['peripheralUUID'] as String,
      lastConnected: DateTime.parse(json['lastConnected'] as String),
      isPaired: json['isPaired'] as bool,
    );
  }

  Device copyWith({
    String? id,
    String? name,
    String? peripheralUUID,
    DateTime? lastConnected,
    bool? isPaired,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      peripheralUUID: peripheralUUID ?? this.peripheralUUID,
      lastConnected: lastConnected ?? this.lastConnected,
      isPaired: isPaired ?? this.isPaired,
    );
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, peripheralUUID: $peripheralUUID, lastConnected: $lastConnected, isPaired: $isPaired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Device &&
        other.id == id &&
        other.name == name &&
        other.peripheralUUID == peripheralUUID &&
        other.lastConnected == lastConnected &&
        other.isPaired == isPaired;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        peripheralUUID.hashCode ^
        lastConnected.hashCode ^
        isPaired.hashCode;
  }
}
