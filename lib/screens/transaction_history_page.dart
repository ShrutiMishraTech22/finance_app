import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class TransactionHistoryPage extends StatelessWidget {
  Future<void> _openBoxes() async {
    if (!Hive.isBoxOpen('income')) await Hive.openBox('income');
    if (!Hive.isBoxOpen('expenses')) await Hive.openBox('expenses');
  }

  List<Map<String, dynamic>> _getCombinedTransactions() {
    final incomeBox = Hive.box('income');
    final expenseBox = Hive.box('expense');

    List<Map<String, dynamic>> incomes = incomeBox.values.map((e) {
      return {
        'type': 'Income',
        'amount': e['amount'],
        'desc': e['source'] ?? 'Income',
        'mode': 'N/A',
        'date': DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
      };
    }).toList();

    List<Map<String, dynamic>> expenses = expenseBox.values.map((e) {
      return {
        'type': 'Expense',
        'amount': e['amount'],
        'desc': e['note'] ?? 'Expense',
        'mode': e['category'] ?? 'General',
        'date': DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
      };
    }).toList();

    final all = [...incomes, ...expenses];
    all.sort((a, b) => b['date'].compareTo(a['date']));
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _openBoxes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final transactions = _getCombinedTransactions();

        return Scaffold(
          appBar: AppBar(title: Text('Transaction History')),
          body: transactions.isEmpty
              ? Center(child: Text('No transactions available.'))
              : ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isIncome = tx['type'] == 'Income';
              return ListTile(
                leading: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
                title: Text(
                  '₹ ${tx['amount']}',
                  style: TextStyle(
                      color: isIncome ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${tx['desc']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tx['mode']),
                    SizedBox(height: 4),
                    Text(
                      tx['date'].toString().split(' ')[0],
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
