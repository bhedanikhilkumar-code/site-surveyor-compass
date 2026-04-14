import 'package:hive/hive.dart';

part 'project_model.g.dart';

@HiveType(typeId: 3)
class SiteProject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final String color;

  @HiveField(6)
  final String? clientName;

  @HiveField(7)
  final String? location;
   SiteProject({
     required this.id,
     required this.name,
     this.description = "",
     required this.createdAt,
     DateTime? updatedAt,
     this.color = "#2196F3",
     this.clientName,
     this.location,
   }) : updatedAt = updatedAt ?? createdAt;


  SiteProject copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? clientName,
    String? location,
  }) {
    return SiteProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      clientName: clientName ?? this.clientName,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'color': color,
        'clientName': clientName,
        'location': location,
      };

  factory SiteProject.fromJson(Map<String, dynamic> json) {
    return SiteProject(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      color: json['color'] as String? ?? '#2196F3',
      clientName: json['clientName'] as String?,
      location: json['location'] as String?,
    );
  }
}
