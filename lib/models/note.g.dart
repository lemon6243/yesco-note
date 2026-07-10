// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 1;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      content: fields[1] as String,
      status: fields[2] as NoteStatus,
      createdAt: fields[3] as DateTime,
      penImagePath: fields[4] as String?,
      convertedText: fields[5] as String?,
      convertedTaskId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.penImagePath)
      ..writeByte(5)
      ..write(obj.convertedText)
      ..writeByte(6)
      ..write(obj.convertedTaskId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteStatusAdapter extends TypeAdapter<NoteStatus> {
  @override
  final int typeId = 2;

  @override
  NoteStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NoteStatus.unclassified;
      case 1:
        return NoteStatus.archived;
      case 2:
        return NoteStatus.converted;
      default:
        return NoteStatus.unclassified;
    }
  }

  @override
  void write(BinaryWriter writer, NoteStatus obj) {
    switch (obj) {
      case NoteStatus.unclassified:
        writer.writeByte(0);
        break;
      case NoteStatus.archived:
        writer.writeByte(1);
        break;
      case NoteStatus.converted:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
