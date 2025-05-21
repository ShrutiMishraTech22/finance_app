import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AlertSettingsPage extends StatefulWidget {
  @override
  _AlertSettingsPageState createState() => _AlertSettingsPageState();
}

class _AlertSettingsPageState extends State<AlertSettingsPage> {
  final thresholdController = TextEditingController();
  List<double> thresholds = [];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('alerts');
    thresholds = List<double>.from(box.get('thresholds', defaultValue: []));
  }

  void _addThreshold() {
    final value = double.tryParse(thresholdController.text);
    if (value != null && value > 0 && !thresholds.contains(value)) {
      setState(() {
        thresholds.add(value);
        thresholds.sort();
      });
      Hive.box('alerts').put('thresholds', thresholds);
      thresholdController.clear();
    }
  }

  void _removeThreshold(double value) {
    setState(() {
      thresholds.remove(value);
    });
    Hive.box('alerts').put('thresholds', thresholds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Alert Notification Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: thresholdController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Add New Alert Threshold (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addThreshold,
              child: Text("Add Threshold"),
            ),
            SizedBox(height: 20),
            Text("Active Thresholds:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView(
                children: thresholds.map((t) {
                  return ListTile(
                    title: Text("₹${t.toStringAsFixed(2)}"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeThreshold(t),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
