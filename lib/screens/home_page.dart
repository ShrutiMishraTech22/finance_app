import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';
import 'upcoming_bills_page.dart';
import 'transaction_history_page.dart';
late Box billsBox;
late Box incomeBox;


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<double> dailyExpenses;
  List<Map<String, dynamic>> incomeRecords = [];
  late Box billsBox;

  double get totalExpense => dailyExpenses.fold(0, (a, b) => a + b);
  double get totalIncome => incomeRecords.fold(0, (sum, e) => sum + e['amount']);

  bool showMenu = false;

  @override
  void initState() {
    super.initState();
    incomeBox = Hive.box('income');

    incomeRecords = incomeBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

    final expenseBox = Hive.box('expenses');
    billsBox = Hive.box('bills'); // <-- Initialize billsBox here

    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    dailyExpenses = List.generate(7, (_) => 0.0);

    for (var expense in expenseBox.values) {
      final date = DateTime.tryParse(expense['date'] ?? '');
      final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;

      if (date != null &&
          date.isAfter(weekStart.subtract(Duration(days: 1))) &&
          date.isBefore(today.add(Duration(days: 1)))) {
        final index = date.weekday - 1; // Monday is 1
        dailyExpenses[index] += amount;
      }
    }
  }

  void _addRecordDialog(String type) {
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            onPressed: () {
              double? amount = double.tryParse(_amountController.text);
              if (amount != null) {
                setState(() {
                  if (type == 'Expense') {
                    dailyExpenses[dailyExpenses.length - 1] += amount;
                  } else {
                    incomeRecords.add({
                      'amount': amount,
                      'source': _noteController.text,
                      'date': DateTime.now().toString().split(' ')[0]
                    });
                  }
                });
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
    final upcomingBills = billsBox.values.toList().cast<Map>();

    return Scaffold(
      appBar: AppBar(title: Text('Finance Dashboard')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/logo.png'),
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text('Finance Tracker',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('by Your Name', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Finance Tracker',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 SHRUTI MISHRA',
                  children: [Text('This app helps students track expenses and income.')],
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Transaction History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TransactionHistoryPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text("Weekly Expenses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 250,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(days[value.toInt()]),
                                );
                              } else {
                                return Text('');
                              }
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: dailyExpenses.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [BarChartRodData(toY: entry.value, color: Colors.green)],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Tooltip(
                  message: "This month",
                  child: _summaryRow('Total Expense', totalExpense, Colors.green[50]!),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TotalIncomePage(incomeRecords)));
                  },
                  child: Tooltip(
                    message: "Click to view income records",
                    child: _summaryRow('Total Income', totalIncome, Colors.blue[50]!),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UpcomingBillsPage()));
                  },
                  child: Tooltip(
                    message: "Tap to view all upcoming bills",
                    child: _summaryRow(
                      'Upcoming Bills',
                      _getNextBillText(upcomingBills),
                      Colors.orange[50]!,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showMenu) ...[
                  FloatingActionButton.small(
                    heroTag: "addIncome",
                    backgroundColor: Colors.green,
                    onPressed: () {
                      _addRecordDialog('Income');
                      setState(() => showMenu = false);
                    },
                    child: Icon(Icons.currency_rupee_rounded),
                    tooltip: 'Add Income',
                  ),
                  SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: "addExpense",
                    backgroundColor: Colors.red,
                    onPressed: () {
                      _addRecordDialog('Expense');
                      setState(() => showMenu = false);
                    },
                    child: Icon(Icons.currency_rupee_rounded),
                    tooltip: 'Add Expense',
                  ),
                  SizedBox(height: 8),
                ],
                FloatingActionButton(
                  heroTag: "mainBubble",
                  mini: true,
                  onPressed: () => setState(() => showMenu = !showMenu),
                  child: Icon(showMenu ? Icons.close : Icons.add),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String label, dynamic value, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(
            value is double ? '₹ ${value.toStringAsFixed(2)}' : value.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getNextBillText(List<Map> bills) {
    final now = DateTime.now();
    final upcoming = bills.where((bill) {
      final dueDate = DateTime.tryParse(bill['dueDate'] ?? '');
      return dueDate != null && dueDate.isAfter(now) && dueDate.isBefore(now.add(Duration(days: 7)));
    }).toList();

    if (upcoming.isEmpty) return "No due in 7 days";

    upcoming.sort((a, b) => DateTime.parse(a['dueDate']).compareTo(DateTime.parse(b['dueDate'])));
    final next = upcoming.first;
    return "${next['desc']} - ₹${next['amount']}";
  }
}

class TotalIncomePage extends StatelessWidget {
  late Box incomeBox;
  List<Map<String, dynamic>> incomeRecords = [];
  TotalIncomePage(this.incomeRecords);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Total Income')),
      body: incomeRecords.isEmpty
          ? Center(child: Text('No income records yet.'))
          : ListView.builder(
        itemCount: incomeRecords.length,
        itemBuilder: (context, index) {
          final record = incomeRecords[index];
          return ListTile(
            leading: Icon(Icons.attach_money, color: Colors.green),
            title: Text('₹ ${record['amount']}'),
            subtitle: Text('${record['source']} - ${record['date']}'),
          );
        },
      ),
    );
  }
}
