import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 6)
class Goal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String icon;

  @HiveField(4)
  double targetAmount;

  @HiveField(5)
  double currentAmount;

  @HiveField(6)
  DateTime targetDate;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  String level;

  @HiveField(9)
  String levelColor;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.icon,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.isCompleted,
    required this.level,
    required this.levelColor,
    required this.createdAt,
    required this.updatedAt,
  });
}
