import 'package:finance/screens/home_page.dart';
import 'package:finance/screens/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('users');
  await Hive.openBox('income');
  await Hive.openBox('bills');
  await Hive.openBox('expense');
  await Hive.openBox('alerts');
  await Hive.openBox('auth');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
    );
  }
}
