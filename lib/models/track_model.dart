import 'package:hive/hive.dart';

part 'track_model.g.dart';

@HiveType(typeId: 1)
class TrackPoint {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final double altitude;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final double? speed;

  @HiveField(5)
  final double? accuracy;

  TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
    this.speed,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'timestamp': timestamp.toIso8601String(),
        'speed': speed,
        'accuracy': accuracy,
      };

  factory TrackPoint.fromJson(Map<String, dynamic> json) {
    return TrackPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }
}

@HiveType(typeId: 2)
class Track {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String projectId;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime? endTime;

  @HiveField(5)
  final List<TrackPoint> points;

  @HiveField(6)
  final double totalDistance;

  @HiveField(7)
  final String color;

  Track({
    required this.id,
    required this.name,
    required this.projectId,
    required this.startTime,
    this.endTime,
    required this.points,
    this.totalDistance = 0.0,
    this.color = '#00BCD4',
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isRecording => endTime == null;

  double get averageSpeed {
    if (points.length < 2 || duration.inSeconds == 0) return 0.0;
    return (totalDistance / duration.inSeconds) * 3.6;
  }

  Track copyWith({
    String? id,
    String? name,
    String? projectId,
    DateTime? startTime,
    DateTime? endTime,
    List<TrackPoint>? points,
    double? totalDistance,
    String? color,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      projectId: projectId ?? this.projectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      points: points ?? this.points,
      totalDistance: totalDistance ?? this.totalDistance,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'projectId': projectId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'points': points.map((p) => p.toJson()).toList(),
        'totalDistance': totalDistance,
        'color': color,
      };

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      name: json['name'] as String,
      projectId: json['projectId'] as String? ?? 'default',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      points: (json['points'] as List<dynamic>)
          .map((p) => TrackPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ?? '#00BCD4',
    );
  }
}
