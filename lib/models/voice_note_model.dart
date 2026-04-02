import 'package:hive/hive.dart';

part 'voice_note_model.g.dart';

@HiveType(typeId: 4)
class VoiceNote extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String filePath;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  double? latitude;

  @HiveField(4)
  double? longitude;

  @HiveField(5)
  int durationMs;

  @HiveField(6)
  String name;

  VoiceNote({
    required this.id,
    required this.filePath,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.durationMs,
    required this.name,
  });

  Duration get duration => Duration(milliseconds: durationMs);

  set duration(Duration value) => durationMs = value.inMilliseconds;

  VoiceNote copyWith({
    String? id,
    String? filePath,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    int? durationMs,
    String? name,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      durationMs: durationMs ?? this.durationMs,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'durationMs': durationMs,
        'name': name,
      };

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      durationMs: json['durationMs'] as int,
      name: json['name'] as String,
    );
  }
}
