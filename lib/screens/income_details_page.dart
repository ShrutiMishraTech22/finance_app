import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class IncomeDetailsPage extends StatefulWidget {
  final List<Map<String, dynamic>> incomes;

  IncomeDetailsPage({required this.incomes});

  @override
  State<IncomeDetailsPage> createState() => _IncomeDetailsPageState();
}

class _IncomeDetailsPageState extends State<IncomeDetailsPage> {
  late Box incomeBox;

  @override
  void initState() {
    super.initState();
    incomeBox = Hive.box('income');
  }

  void _showEditDialog(int index, Map<String, dynamic> income) {
    final _amountController =
    TextEditingController(text: income['amount'].toString());
    final _sourceController =
    TextEditingController(text: income['source'] ?? '');
    DateTime selectedDate =
        DateTime.tryParse(income['date'] ?? '') ?? DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Edit Income"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: _sourceController,
                  decoration: InputDecoration(labelText: 'Source'),
                ),
                Row(
                  children: [
                    Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                    Spacer(),
                    TextButton(
                      child: Text("Pick Date"),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                incomeBox.deleteAt(index);
                Navigator.pop(context);
                setState(() {}); // Refresh list
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                final updated = {
                  'amount': double.tryParse(_amountController.text) ?? 0.0,
                  'source': _sourceController.text,
                  'date': selectedDate.toIso8601String(),
                };
                incomeBox.putAt(index, updated);
                Navigator.pop(context);
                setState(() {}); // Refresh list
              },
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatedIncomes =
    incomeBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Income Details')),
      body: ListView.builder(
        itemCount: updatedIncomes.length,
        itemBuilder: (context, index) {
          final income = updatedIncomes[index];
          return ListTile(
            title: Text('₹${income['amount']} - ${income['source']}'),
            subtitle: Text('Date: ${DateTime.parse(income['date']).toLocal().toString().split(' ')[0]}'),
            leading: Icon(Icons.arrow_downward, color: Colors.green),
            onTap: () => _showEditDialog(index, income),
          );
        },
      ),
    );
  }
}
