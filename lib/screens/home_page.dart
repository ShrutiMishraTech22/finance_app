import 'income_details_page.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'upcoming_bills_page.dart';
import 'transaction_history_page.dart';
import 'expense_details_page.dart';
import 'alert_settings_page.dart';
import 'expense_overview_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> incomeRecords = [];
  late Box billsBox;
  late Box incomeBox;
  late Box expenseBox;
  late Box alertBox;

  List<double> dailyExpenses = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();
    incomeBox = Hive.box('income');
    billsBox = Hive.box('bills');
    expenseBox = Hive.box('expense');
    alertBox = Hive.box('alerts');

    _reloadData();

    incomeBox.watch().listen((_) => _reloadData());
    expenseBox.watch().listen((_) => _reloadData());
  }

  void _reloadData() {
    incomeRecords = incomeBox.values.map((e) => Map<String, dynamic>.from(e)).toList();

    dailyExpenses = List.filled(7, 0.0);
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAlerts());
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

  double get balance => totalIncome - totalExpense;

  void _checkAlerts() {
    final thresholds = alertBox.get('thresholds', defaultValue: []).cast<double>();
    final currentBalance = balance;

    for (var t in thresholds) {
      if (currentBalance < t) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Alert: Balance ₹${currentBalance.toStringAsFixed(2)} is below threshold ₹${t.toStringAsFixed(2)}!"),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
        break;
      }
    }
  }

  void _addRecordDialog(String type) {
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedCategory = 'Food';
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
                if (type == 'Expense')
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
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Amount'),
                ),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(labelText: type == 'Expense' ? 'Note' : 'Source'),
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
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      child: Text('Select Date'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
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
              ),
            ],
          );
        },
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
    double maxY = (dailyExpenses.reduce((a, b) => a > b ? a : b));
    maxY = (maxY / 100).ceil() * 100; // round up to next 100
    if (maxY < 200) maxY = 200;
    return Scaffold(
      appBar: AppBar(title: Text('Finance Dashboard')),
      drawer: Drawer(
        child: ListView(
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
                  Text('Finance Tracker', style: TextStyle(color: Colors.white, fontSize: 18)),
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
              leading: Icon(Icons.pie_chart),
              title: Text('Expense Categories Overview'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseOverviewPage(expenseBox: expenseBox),
                  ),
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
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Alert Notification Setting'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlertSettingsPage()),
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
                SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarChart(
    BarChartData(
    alignment: BarChartAlignment.spaceBetween,
    maxY: maxY,
    barGroups: List.generate(7, (i) {
    final value = dailyExpenses[i];
    return BarChartGroupData(
    x: i,
    barRods: [
    BarChartRodData(
    toY: value > 0 ? value : 1,
    width: 22,
    borderRadius: BorderRadius.circular(6),
    color: Colors.teal,
    ),
    ],
    );
    }),
    titlesData: FlTitlesData(
    leftTitles: AxisTitles(
    sideTitles: SideTitles(
    showTitles: true,
    interval: 100, // fixed interval of 100 units
    reservedSize: 40,
    getTitlesWidget: (value, _) =>
    Text('₹${value.toInt()}', style: TextStyle(fontSize: 10)),
    ),
    ),
    bottomTitles: AxisTitles(
    sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 28,
    getTitlesWidget: (value, _) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
    padding: EdgeInsets.only(top: 6),
    child: Text(days[value.toInt()], style: TextStyle(fontSize: 12)),
    );
    },
    ),
    ),
    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    gridData: FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: 100, // match interval here too
    getDrawingHorizontalLine: (value) => FlLine(
    color: Colors.grey.shade300,
    strokeWidth: 1,
    ),
    ),
    borderData: FlBorderData(show: false),
    ),

    ),
                ),
                SizedBox(height: 20),

                Center(
                  child: Column(
                    children: [
                      Text("Balance", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      Text(
                        '₹ ${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: balance < 0 ? Colors.red : Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncomeDetailsPage(incomes: incomeRecords),
                      ),
                    );
                  },
                  child: _summaryRow('Total Income', totalIncome, Colors.green[50]!),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseDetailsPage(
                          expenses: expenseBox.values.toList().cast<Map<String, dynamic>>(),
                        ),
                      ),
                    );
                  },
                  child: _summaryRow('Total Expense (Monthly)', totalExpense, Colors.red[50]!),
                ),

                SizedBox(height: 16),

                Material(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UpcomingBillsPage()),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upcoming Bills',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _getNextBillText(upcomingBills),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Color(0xFFB39DDB), // lilac color
              shape: CircleBorder(),
              elevation: 6,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.add, color: Colors.white),
                color: Color(0xFFB39DDB).withOpacity(0.95), // lilac background for menu
                onSelected: (value) {
                  if (value == 'Expense') {
                    _addRecordDialog('Expense');
                  } else if (value == 'Income') {
                    _addRecordDialog('Income');
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'Expense',
                    child: Text('Add Expense'),
                  ),
                  PopupMenuItem(
                    value: 'Income',
                    child: Text('Add Income'),
                  ),
                ],
              ),
            ),
          ),
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
}
