import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UpcomingBillsPage extends StatefulWidget {
  @override
  _UpcomingBillsPageState createState() => _UpcomingBillsPageState();
}

class _UpcomingBillsPageState extends State<UpcomingBillsPage> {
  late Box billsBox;

  @override
  void initState() {
    super.initState();
    billsBox = Hive.box('bills');
  }

  void _addBillDialog() {
    final _amountController = TextEditingController();
    final _descController = TextEditingController();
    final _dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Upcoming Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final desc = _descController.text.trim();
              final amount = double.tryParse(_amountController.text.trim());
              final dueDate = _dateController.text.trim();

              if (desc.isNotEmpty && amount != null && dueDate.isNotEmpty) {
                billsBox.add({
                  'desc': desc,
                  'amount': amount,
                  'dueDate': dueDate,
                });
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upcoming Bills")),
      body: ValueListenableBuilder(
        valueListenable: billsBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(child: Text("No upcoming bills added yet."));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final bill = box.getAt(index);
              return ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.orange),
                title: Text('${bill['desc']}'),
                subtitle: Text('Due: ${bill['dueDate']}'),
                trailing: Text('₹ ${bill['amount']}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBillDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Bill',
      ),
    );
  }
}
