// screens/welcome_page.dart
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _showLogin = false;

  void _revealLogin() {
    setState(() {
      _showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onVerticalDragEnd: (_) => _revealLogin(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 100),
              Text('Finance', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Icon(Icons.account_balance_wallet, size: 100, color: Colors.green),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _revealLogin,
                child: Text("Let's get started", style: TextStyle(fontSize: 18)),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showLogin ? 300 : 0,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: _showLogin ? 30 : 0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: _showLogin
                    ? Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage())),
                      child: Text('Login with PIN'),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpPage())),
                          child: Text('Sign up', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                )
                    : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}