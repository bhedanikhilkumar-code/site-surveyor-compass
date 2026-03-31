import 'package:hive/hive.dart';

part 'waypoint_model.g.dart';

@HiveType(typeId: 0)
class Waypoint {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double bearing;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;

  @HiveField(5)
  final double altitude;

  @HiveField(6)
  final String notes;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  Waypoint({
    required this.id,
    required this.name,
    required this.bearing,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.notes = '',
    required this.createdAt,
    this.updatedAt,
  });

  Waypoint copyWith({
    String? id,
    String? name,
    double? bearing,
    double? latitude,
    double? longitude,
    double? altitude,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Waypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      bearing: bearing ?? this.bearing,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Waypoint(id: $id, name: $name, bearing: $bearing, lat: $latitude, lng: $longitude)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bearing': bearing,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
        id: json['id'] as String,
        name: json['name'] as String,
        bearing: (json['bearing'] as num).toDouble(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        altitude: (json['altitude'] as num).toDouble(),
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}
