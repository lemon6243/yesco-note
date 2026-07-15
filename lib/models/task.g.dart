// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      memo: fields[2] as String?,
      startTime: fields[3] as DateTime?,
      date: fields[4] as DateTime,
      isImportant: fields[5] as bool,
      isUrgent: fields[6] as bool,
      isTop3: fields[7] as bool,
      isDone: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      carriedOverFromId: fields[10] as String?,
      location: fields[11] as String?,
      why: fields[12] as String?,
      how: fields[13] as String?,
      howMuch: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.memo)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.isImportant)
      ..writeByte(6)
      ..write(obj.isUrgent)
      ..writeByte(7)
      ..write(obj.isTop3)
      ..writeByte(8)
      ..write(obj.isDone)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.carriedOverFromId)
      ..writeByte(11)
      ..write(obj.location)
      ..writeByte(12)
      ..write(obj.why)
      ..writeByte(13)
      ..write(obj.how)
      ..writeByte(14)
      ..write(obj.howMuch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
