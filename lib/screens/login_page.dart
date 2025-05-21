import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _pinController = TextEditingController();

  void _login() {
    final usersBox = Hive.box('users');
    final pin = _pinController.text.trim();

    final userEntry = usersBox.values.cast<Map>().firstWhere(
          (user) => user['pin'].toString() == pin,
      orElse: () => {},
    );

    if (userEntry != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login successful!")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid PIN")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Enter 4-digit PIN',
                counterText: '', // hides the character counter
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
