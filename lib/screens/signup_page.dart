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
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  String? _selectedGender;

  String _successMessage = '';

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      // Ensure PIN and confirm PIN match
      if (_pinController.text != _confirmPinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PINs do not match")),
        );
        return;
      }

      final usersBox = Hive.box('users');

      final contactKey = _contactController.text.trim();

      // Check if contact already exists (unique key)
      if (usersBox.containsKey(contactKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User with this contact already exists")),
        );
        return;
      }

      // Save user data with contact number as key
      await usersBox.put(contactKey, {
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'sex': _selectedGender,
        'pin': _pinController.text.trim(),
      });

      // Optionally save signup status or other settings
      final settingsBox = await Hive.openBox('settings');
      settingsBox.put('isSignedUp', true);

      setState(() {
        _successMessage = 'Account successfully created!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account Created Successfully!")),
      );

      // Navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );

      // Reset form if you want
      _formKey.currentState!.reset();
      _selectedGender = null;
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    super.dispose();
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
                validator: (value) =>
                value!.isEmpty ? 'Please enter your name' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Sex'),
                value: _selectedGender,
                items: ['Male', 'Female', 'Prefer Not to Say']
                    .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please select an option' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Age is required';
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
                  if (value == null || value.isEmpty) return 'Contact number is required';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
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
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'PIN is required';
                  if (value.length != 4) return 'PIN must be 4 digits';
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
