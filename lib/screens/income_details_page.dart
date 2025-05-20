import 'package:flutter/material.dart';

class IncomeDetailsPage extends StatelessWidget {
  final List<Map<String, dynamic>> incomes = [
    {'amount': 500, 'date': '2025-05-01', 'source': 'Part-time job'},
    {'amount': 300, 'date': '2025-05-05', 'source': 'Scholarship'},
    {'amount': 400, 'date': '2025-05-10', 'source': 'Gift'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Income Details')),
      body: ListView.builder(
        itemCount: incomes.length,
        itemBuilder: (context, index) {
          final income = incomes[index];
          return ListTile(
            title: Text('₹${income['amount']} - ${income['source']}'),
            subtitle: Text('Date: ${income['date']}'),
            leading: Icon(Icons.arrow_downward, color: Colors.green),
          );
        },
      ),
    );
  }
}
