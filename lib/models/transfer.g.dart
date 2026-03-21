// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransferAdapter extends TypeAdapter<Transfer> {
  @override
  final int typeId = 4;

  @override
  Transfer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transfer(
      id: fields[0] as String,
      userId: fields[1] as String,
      fromAccountId: fields[2] as String,
      toAccountId: fields[3] as String,
      amount: fields[4] as double,
      date: fields[5] as DateTime,
      description: fields[6] as String,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Transfer obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.fromAccountId)
      ..writeByte(3)
      ..write(obj.toAccountId)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
