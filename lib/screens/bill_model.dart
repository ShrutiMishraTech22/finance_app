import 'package:hive/hive.dart';

part 'bill_model.g.dart';

@HiveType(typeId: 1)
class Bill extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String amount;

  @HiveField(2)
  String dueDate;

  Bill({required this.title, required this.amount, required this.dueDate});
}
