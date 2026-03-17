import 'package:hive/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 3)
class Loan extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String bank;

  @HiveField(3)
  String type; // 'personal' | 'mortgage' | 'auto' | 'other'

  @HiveField(4)
  String accountId;

  @HiveField(5)
  double totalAmount;

  @HiveField(6)
  double remainingAmount;

  @HiveField(7)
  double monthlyPayment;

  @HiveField(8)
  double interestRate;

  @HiveField(9)
  DateTime startDate;

  @HiveField(10)
  DateTime endDate;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  Loan({
    required this.id,
    required this.name,
    required this.bank,
    required this.type,
    required this.accountId,
    required this.totalAmount,
    required this.remainingAmount,
    required this.monthlyPayment,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });
}
