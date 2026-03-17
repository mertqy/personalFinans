import 'package:hive/hive.dart';

part 'transfer.g.dart';

@HiveType(typeId: 4)
class Transfer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String fromAccountId;

  @HiveField(3)
  String toAccountId;

  @HiveField(4)
  double amount;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String description;

  @HiveField(7)
  DateTime createdAt;

  Transfer({
    required this.id,
    required this.userId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    required this.description,
    required this.createdAt,
  });
}
