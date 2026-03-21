import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String type; // 'income' | 'expense'

  @HiveField(3)
  double amount;

  @HiveField(4)
  String category;

  @HiveField(5)
  String description;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  bool isPlanned;

  @HiveField(8)
  bool? isRecurring;

  @HiveField(9)
  String? recurringFrequency; // 'daily' | 'weekly' | 'monthly' | 'yearly'

  @HiveField(10)
  double? locationLat;

  @HiveField(11)
  double? locationLng;

  @HiveField(12)
  String accountId;

  @HiveField(13)
  String? creditCardId;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime updatedAt;

  @HiveField(16)
  String? toAccountId;

  @HiveField(17)
  String? toGoalId;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.isPlanned,
    this.isRecurring,
    this.recurringFrequency,
    this.locationLat,
    this.locationLng,
    required this.accountId,
    this.creditCardId,
    this.toAccountId,
    this.toGoalId,
    required this.createdAt,
    required this.updatedAt,
  });
}
