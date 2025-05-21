import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ExpenseDetailsPage extends StatefulWidget {
  final List<Map<String, dynamic>> expenses;

  const ExpenseDetailsPage({Key? key, required this.expenses}) : super(key: key);

  @override
  State<ExpenseDetailsPage> createState() => _ExpenseDetailsPageState();
}

class _ExpenseDetailsPageState extends State<ExpenseDetailsPage> {
  late Box expenseBox;

  @override
  void initState() {
    super.initState();
    expenseBox = Hive.box('expense');
  }

  void _showEditDialog(int index, Map<String, dynamic> expense) {
    final _amountController =
    TextEditingController(text: expense['amount'].toString());
    final _noteController =
    TextEditingController(text: expense['note'] ?? '');
    String selectedCategory = expense['category'] ?? 'Miscellaneous';
    DateTime selectedDate =
        DateTime.tryParse(expense['date'] ?? '') ?? DateTime.now();

    final categories = [
      'Food',
      'Fees',
      'Transport',
      'Entertainment',
      'Education',
      'Miscellaneous'
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Edit Expense"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                ),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(labelText: 'Note'),
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
                expenseBox.deleteAt(index);
                Navigator.pop(context);
                setState(() {}); // Refresh list
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                final updated = {
                  'amount': double.tryParse(_amountController.text) ?? 0.0,
                  'category': selectedCategory,
                  'note': _noteController.text,
                  'date': selectedDate.toIso8601String(),
                };
                expenseBox.putAt(index, updated);
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
    final updatedExpenses =
    expenseBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Expense Details')),
      body: ListView.builder(
        itemCount: updatedExpenses.length,
        itemBuilder: (context, index) {
          final expense = updatedExpenses[index];
          return ListTile(
            title: Text('₹${expense['amount'].toStringAsFixed(2)}'),
            subtitle: Text('${expense['note'] ?? ''} • ${expense['category'] ?? ''}'),
            trailing: Text(
              expense['date'] != null
                  ? DateTime.parse(expense['date']).toLocal().toString().split(' ')[0]
                  : '',
            ),
            onTap: () => _showEditDialog(index, expense),
          );
        },
      ),
    );
  }
}
