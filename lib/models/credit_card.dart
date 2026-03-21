import 'package:hive/hive.dart';

part 'credit_card.g.dart';

@HiveType(typeId: 2)
class CreditCard extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String bank;

  @HiveField(4)
  String accountId;

  @HiveField(5)
  double limit;

  @HiveField(6)
  double currentDebt;

  @HiveField(7)
  int statementDay;

  @HiveField(8)
  int dueDay;

  @HiveField(9)
  String color;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  CreditCard({
    required this.id,
    required this.userId,
    required this.name,
    required this.bank,
    required this.accountId,
    required this.limit,
    required this.currentDebt,
    required this.statementDay,
    required this.dueDay,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });
}
