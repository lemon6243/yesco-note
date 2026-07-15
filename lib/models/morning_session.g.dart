// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'morning_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MorningSessionAdapter extends TypeAdapter<MorningSession> {
  @override
  final int typeId = 5;

  @override
  MorningSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MorningSession(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      durationSeconds: fields[2] as int,
      targetSeconds: fields[3] as int,
      memo: fields[4] as String?,
      completedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MorningSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.targetSeconds)
      ..writeByte(4)
      ..write(obj.memo)
      ..writeByte(5)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MorningSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
