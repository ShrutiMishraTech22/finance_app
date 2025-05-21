import 'package:finance/screens/income_details_page.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'upcoming_bills_page.dart';
import 'transaction_history_page.dart';
import 'expense_details_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> incomeRecords = [];
  late Box billsBox;
  late Box incomeBox;
  late Box expenseBox;

  List<double> dailyExpenses = List.filled(7, 0.0);

  bool showMenu = false;

  @override
  void initState() {
    super.initState();

    incomeBox = Hive.box('income');
    billsBox = Hive.box('bills');
    expenseBox = Hive.box('expense');

    _reloadData();

    incomeBox.watch().listen((event) => _reloadData());
    expenseBox.watch().listen((event) => _reloadData());
  }

  void _reloadData() {
    incomeRecords = incomeBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    dailyExpenses = List.filled(7, 0.0);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    for (var expense in expenseBox.values) {
      final date = DateTime.tryParse(expense['date'] ?? '');
      final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
      if (date != null &&
          !date.isBefore(weekStart) &&
          !date.isAfter(weekStart.add(Duration(days: 6)))) {
        int index = date.weekday - 1;
        dailyExpenses[index] += amount;
      }
    }

    setState(() {});
  }

  double get totalExpense {
    final now = DateTime.now();
    double monthlyTotal = 0;
    for (var expense in expenseBox.values) {
      final date = DateTime.tryParse(expense['date'] ?? '');
      final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;
      if (date != null && date.year == now.year && date.month == now.month) {
        monthlyTotal += amount;
      }
    }
    return monthlyTotal;
  }

  double get totalIncome => incomeRecords.fold(0, (sum, e) => sum + (e['amount'] ?? 0));

  void _addRecordDialog(String type) {
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedCategory = 'Food';  // default category
    final categories = ['Food', 'Fees', 'Transport', 'Entertainment', 'Education', 'Miscellaneous'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add $type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == 'Expense') ...[
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(labelText: 'Category'),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedCategory = value);
                    },
                  ),
                ],
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                      labelText: type == 'Expense' ? 'Note' : 'Source'),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                    Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text('Select Date'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                onPressed: () async {
                  double? amount = double.tryParse(_amountController.text);
                  if (amount != null) {
                    final dateStr = selectedDate.toIso8601String();
                    if (type == 'Expense') {
                      await expenseBox.add({
                        'amount': amount,
                        'date': dateStr,
                        'category': selectedCategory,
                        'note': _noteController.text,
                      });
                    } else {
                      await incomeBox.add({
                        'amount': amount,
                        'source': _noteController.text,
                        'date': dateStr,
                      });
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text('Add'),
              )
            ],
          );
        },
      ),
    );
  }

  double get balance => totalIncome - totalExpense;


  Widget _summaryRow(String label, dynamic value, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration:
      BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
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
      return dueDate != null &&
          dueDate.isAfter(now) &&
          dueDate.isBefore(now.add(Duration(days: 7)));
    }).toList();

    if (upcoming.isEmpty) return "No due in 7 days";

    upcoming.sort((a, b) =>
        DateTime.parse(a['dueDate']).compareTo(DateTime.parse(b['dueDate'])));
    final next = upcoming.first;
    return "${next['desc']} - ₹${next['amount']}";
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
                  children: [
                    Text('This app helps students track expenses and income.')
                  ],
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Transaction History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => TransactionHistoryPage()));
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
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                Text("Weekly Expenses",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),

                // Chart Section
                SizedBox(
                  height: 250,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 300,
                        barGroups: List.generate(7, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: dailyExpenses[i],
                                color: Colors.green,
                                width: 18,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() < days.length) {
                                  return Text(days[value.toInt()]);
                                }
                                return Text('');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],  // light purple background (you can change color)
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '₹ ${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Total Expense
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseDetailsPage(
                          expenses: expenseBox.values
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList(),
                        ),
                      ),
                    );
                  },
                  child: Tooltip(
                    message: "Click to view expense records",
                    child: _summaryRow('Total Expense', totalExpense, Colors.green[50]!),
                  ),
                ),

                SizedBox(height: 10),

                // Total Income
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncomeDetailsPage(incomes: incomeRecords),
                      ),
                    );
                  },
                  child: Tooltip(
                    message: "Click to view income records",
                    child: _summaryRow('Total Income', totalIncome, Colors.blue[50]!),
                  ),
                ),

                SizedBox(height: 20),

                // Upcoming Bills
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => UpcomingBillsPage()));
                  },
                  child: Tooltip(
                    message: "Tap to view all upcoming bills",
                    child: _summaryRow(
                        'Upcoming Bills', _getNextBillText(upcomingBills), Colors.orange[50]!),
                  ),
                ),
              ],
            ),
          ),

          // Floating action buttons
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
          ),
        ],
      ),
    );
  }}
