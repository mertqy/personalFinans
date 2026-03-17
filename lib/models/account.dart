import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 0)
class Account extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String name;

  // 'cash' | 'bank' | 'savings' | 'investment'
  @HiveField(3)
  String type;

  @HiveField(4)
  double balance;

  @HiveField(5)
  String currency;

  @HiveField(6)
  String? color;

  @HiveField(7)
  String? icon;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });
}
