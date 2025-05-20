import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'home_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  final _contactController = TextEditingController();

  String _successMessage = ''; // To store the success message

 Future <void> _signUp() async{
    if (_formKey.currentState!.validate()) {
      // Check if the PINs match
      if (_pinController.text != _confirmPinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PINs do not match")));
        return;
      }

      // Open Hive box and save the user data along with PIN
      final usersBox = Hive.box('users');
      final email = _emailController.text.trim();

      if (usersBox.containsKey(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User already exists!")),
        );
        return;
      }

      usersBox.put(_emailController.text.trim(), {
        'name': _nameController.text.trim(),
        'email': email,
        'age': _ageController.text.trim(),
        'sex': _selectedGender,
        'contact': _contactController.text.trim(),
        'pin': _pinController.text.trim(),
      });

// Save a flag that user has signed up (in a separate box)
      final settingsBox = await Hive.openBox('settings');
      settingsBox.put('isSignedUp', true);

// Navigate to home directly
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );

      // Display success message
      setState(() {
        _successMessage = 'Account successfully created!';
      });

      // Optionally show a message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Account Created Successfully!")));

      // Reset form after submission (Optional)
      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Sex'),
                value: _selectedGender,
                items: ['Male', 'Female', 'Other'].map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an option';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return 'Enter a valid age';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Contact number is required';
                  } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _pinController,
                obscureText: true,
                decoration: InputDecoration(labelText: '4-digit PIN'),
                keyboardType: TextInputType.number,
                inputFormatters: [LengthLimitingTextInputFormatter(4),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PIN is required';
                  } else if (value.length != 4) {
                    return 'PIN must be 4 digits';
                  }
                  return null;
                },
              ),


              TextFormField(
                controller: _confirmPinController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm PIN'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value != _pinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),


              SizedBox(height: 20),
              ElevatedButton(onPressed: _signUp, child: Text('Sign Up')),
              // Show success message below the button
              if (_successMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    _successMessage,
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
