import 'package:hive/hive.dart';

part 'tagged_photo.g.dart';

@HiveType(typeId: 4)
class TaggedPhoto {
  @HiveField(0)
  final String filePath;

  @HiveField(1)
  final double? latitude;

  @HiveField(2)
  final double? longitude;

  @HiveField(3)
  final double? altitude;

  @HiveField(4)
  final double bearing;

  @HiveField(5)
  final double? accuracy;

  @HiveField(6)
  final DateTime timestamp;

  TaggedPhoto({
    required this.filePath,
    this.latitude,
    this.longitude,
    this.altitude,
    required this.bearing,
    this.accuracy,
    required this.timestamp,
  });

  TaggedPhoto copyWith({
    String? filePath,
    double? latitude,
    double? longitude,
    double? altitude,
    double? bearing,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return TaggedPhoto(
      filePath: filePath ?? this.filePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      bearing: bearing ?? this.bearing,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'bearing': bearing,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TaggedPhoto.fromJson(Map<String, dynamic> json) {
    final filePath = json['filePath'];
    if (filePath == null) {
      throw const FormatException('TaggedPhoto JSON missing filePath');
    }
    return TaggedPhoto(
      filePath: filePath as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  String toString() =>
      'TaggedPhoto(path: $filePath, lat: $latitude, lng: $longitude)';
}
