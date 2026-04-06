// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tagged_photo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaggedPhotoAdapter extends TypeAdapter<TaggedPhoto> {
  @override
  final int typeId = 5;

  @override
  TaggedPhoto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaggedPhoto(
      filePath: fields[0] as String,
      latitude: fields[1] as double?,
      longitude: fields[2] as double?,
      altitude: fields[3] as double?,
      bearing: fields[4] as double,
      accuracy: fields[5] as double?,
      timestamp: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TaggedPhoto obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.filePath)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.altitude)
      ..writeByte(4)
      ..write(obj.bearing)
      ..writeByte(5)
      ..write(obj.accuracy)
      ..writeByte(6)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaggedPhotoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
