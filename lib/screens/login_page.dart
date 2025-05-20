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

    final userEntry = usersBox.values.firstWhere(
          (user) => user['pin'].toString() == pin, // Compare as String
      orElse: () => null,
    );

    if (userEntry != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login successful!")));
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: 0.0, end: 1.0);
            final fadeAnimation = animation.drive(tween);

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 600),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid PIN")));
    }
  }

  String _loginMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _pinController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'PIN'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            // Display success message after login
            if (_loginMessage.isNotEmpty)
              Text(_loginMessage, style: TextStyle(fontSize: 18, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
