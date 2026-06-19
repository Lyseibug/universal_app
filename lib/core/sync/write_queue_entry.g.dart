// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_queue_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WriteQueueEntryAdapter extends TypeAdapter<WriteQueueEntry> {
  @override
  final int typeId = 10;

  @override
  WriteQueueEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WriteQueueEntry(
      id: fields[0] as String,
      method: fields[1] as String,
      bodyJson: fields[2] as String,
      status: fields[3] as String,
      createdAt: fields[4] as DateTime,
      syncedAt: fields[5] as DateTime?,
      errorMessage: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WriteQueueEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.method)
      ..writeByte(2)
      ..write(obj.bodyJson)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.syncedAt)
      ..writeByte(6)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WriteQueueEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
