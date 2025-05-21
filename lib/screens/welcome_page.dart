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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60),
              Text(
                'FINANCE',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Icon(Icons.account_balance_wallet, size: 100, color: Colors.green),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _revealLogin,
                child: Text(
                  "LET'S GET STARTED",
                  style: TextStyle(fontSize: 18, color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontFamily: 'Helvetica'),
                ),
              ),
              SizedBox(height: 20),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showLogin ? 150 : 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: _showLogin ? 20 : 0,
                ),
                child: _showLogin
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 22),
                        shape: StadiumBorder(),
                        backgroundColor: Colors.tealAccent,
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text('LOGIN WITH PIN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),

                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? "),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignUpPage()),
                          ),
                          child: Text(
                            'SIGN UP',
                            style: TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
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
