import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 9)
class Debt extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String? creditorName;

  @HiveField(5)
  double totalAmount;

  @HiveField(6)
  double remainingAmount;

  @HiveField(7)
  String currency;

  @HiveField(8)
  DateTime? dueDate;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  bool isCompleted;

  Debt({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.creditorName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.currency,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
  });
}
