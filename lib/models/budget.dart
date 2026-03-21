import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 5)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String categoryId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String period; // 'monthly' | 'yearly'

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.createdAt,
    required this.updatedAt,
  });
}
