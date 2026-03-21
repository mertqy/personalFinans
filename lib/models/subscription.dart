import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 7)
class Subscription extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String category;

  @HiveField(5)
  String accountId;

  @HiveField(6)
  int billingDay; // Ayın günü (1-31)

  @HiveField(7)
  String frequency; // 'monthly' | 'yearly'

  @HiveField(8)
  bool isActive;

  @HiveField(9)
  String icon;

  @HiveField(10)
  String color;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13)
  DateTime? lastProcessedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.billingDay,
    required this.frequency,
    required this.isActive,
    required this.icon,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.lastProcessedAt,
  });
}
