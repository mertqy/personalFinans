import 'package:hive/hive.dart';

part 'exchange_rate.g.dart';

@HiveType(typeId: 8)
class ExchangeRate extends HiveObject {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final double rate;

  @HiveField(2)
  final DateTime lastUpdated;

  ExchangeRate({
    required this.code,
    required this.rate,
    required this.lastUpdated,
  });
}
