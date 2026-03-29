// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waypoint_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaypointAdapter extends TypeAdapter<Waypoint> {
  @override
  final int typeId = 0;

  @override
  Waypoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Waypoint(
      id: fields[0] as String,
      name: fields[1] as String,
      bearing: fields[2] as double,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      altitude: fields[5] as double,
      notes: fields[6] as String? ?? '',
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Waypoint obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bearing)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.altitude)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaypointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
