// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_note_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoiceNoteAdapter extends TypeAdapter<VoiceNote> {
  @override
  final int typeId = 4;

  @override
  VoiceNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceNote(
      id: fields[0] as String,
      filePath: fields[1] as String,
      timestamp: fields[2] as DateTime,
      latitude: fields[3] as double?,
      longitude: fields[4] as double?,
      durationMs: fields[5] as int,
      name: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VoiceNote obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.durationMs)
      ..writeByte(6)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
