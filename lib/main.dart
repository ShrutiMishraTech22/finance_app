// main.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter(); // Initializes Hive with default Flutter directory

  // Open Hive boxes with consistent names
  await Hive.openBox('expenses');
  await Hive.openBox('users');
  await Hive.openBox('income');
  await Hive.openBox('bills'); // Changed from 'upcoming_bills' to 'bills'

  runApp(FinanceApp());
}

class FinanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance',
      theme: ThemeData(primarySwatch: Colors.green),
      home: WelcomePage(),
    );
  }
}
