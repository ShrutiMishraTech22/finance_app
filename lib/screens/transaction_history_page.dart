import 'package:flutter/material.dart';

class TransactionHistoryPage extends StatelessWidget {
  // Dummy list of transactions
  final List<Map<String, String>> transactions = [
    {
      'receiver': 'Amazon',
      'amount': '799.00',
      'mode': 'UPI',
    },
    {
      'receiver': 'Zomato',
      'amount': '250.00',
      'mode': 'Credit Card',
    },
    {
      'receiver': 'Electricity Board',
      'amount': '1240.00',
      'mode': 'Net Banking',
    },
    {
      'receiver': 'Friend (Reema)',
      'amount': '500.00',
      'mode': 'Cash',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction History')),
      body: transactions.isEmpty
          ? Center(child: Text('No transactions available.'))
          : ListView.separated(
        itemCount: transactions.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return ListTile(
            leading: Icon(Icons.swap_horiz, color: Colors.blue),
            title: Text('₹ ${tx['amount']}'),
            subtitle: Text('${tx['receiver']}'),
            trailing: Chip(
              label: Text(tx['mode'] ?? '', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.indigo,
            ),
          );
        },
      ),
    );
  }
}
