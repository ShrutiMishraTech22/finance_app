import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _pinController = TextEditingController();

  void _login() async {
    final usersBox = Hive.box('users');
    final authBox = Hive.box('auth');
    final enteredPin = _pinController.text.trim();

    // Validate PIN
    final matchedUser = usersBox.values.cast<Map>().firstWhere(
          (user) => user['pin'].toString() == enteredPin,
      orElse: () => {},
    );

    if (matchedUser.isNotEmpty) {
      // Save login status
      await authBox.put('isLoggedIn', true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login successful!")),
      );

      // Navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid PIN. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LOGIN')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.blueAccent),
            SizedBox(height: 24),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Enter 4-digit PIN',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[100],
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: Text('LOGIN', style: TextStyle(fontSize: 16, color:Colors.indigo)),
            ),
          ],
        ),
      ),
    );
  }
}
