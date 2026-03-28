// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 1;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      userId: fields[1] as String,
      type: fields[2] as String,
      amount: fields[3] as double,
      category: fields[4] as String,
      description: fields[5] as String,
      date: fields[6] as DateTime,
      isPlanned: fields[7] as bool,
      isRecurring: fields[8] as bool?,
      recurringFrequency: fields[9] as String?,
      locationLat: fields[10] as double?,
      locationLng: fields[11] as double?,
      accountId: fields[12] as String,
      creditCardId: fields[13] as String?,
      toAccountId: fields[16] as String?,
      toGoalId: fields[17] as String?,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.isPlanned)
      ..writeByte(8)
      ..write(obj.isRecurring)
      ..writeByte(9)
      ..write(obj.recurringFrequency)
      ..writeByte(10)
      ..write(obj.locationLat)
      ..writeByte(11)
      ..write(obj.locationLng)
      ..writeByte(12)
      ..write(obj.accountId)
      ..writeByte(13)
      ..write(obj.creditCardId)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.toAccountId)
      ..writeByte(17)
      ..write(obj.toGoalId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
