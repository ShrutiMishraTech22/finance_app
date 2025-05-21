import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive/hive.dart';

class ExpenseOverviewPage extends StatefulWidget {
  final Box expenseBox;

  ExpenseOverviewPage({required this.expenseBox});

  @override
  State<ExpenseOverviewPage> createState() => _ExpenseOverviewPageState();
}

class _ExpenseOverviewPageState extends State<ExpenseOverviewPage> {
  int touchedIndex = -1;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Map<String, double> getMonthlyExpenseByCategory() {
    Map<String, double> categoryTotals = {
      'Food': 0,
      'Fees': 0,
      'Transport': 0,
      'Entertainment': 0,
      'Education': 0,
      'Miscellaneous': 0,
    };

    for (var expense in widget.expenseBox.values) {
      final date = DateTime.tryParse(expense['date'] ?? '');
      final category = expense['category'] ?? 'Miscellaneous';
      final amount = double.tryParse(expense['amount'].toString()) ?? 0.0;

      if (date != null &&
          date.year == selectedMonth.year &&
          date.month == selectedMonth.month) {
        if (categoryTotals.containsKey(category)) {
          categoryTotals[category] = categoryTotals[category]! + amount;
        } else {
          categoryTotals['Miscellaneous'] =
              categoryTotals['Miscellaneous']! + amount;
        }
      }
    }
    return categoryTotals;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Fees':
        return Colors.blue;
      case 'Transport':
        return Colors.green;
      case 'Entertainment':
        return Colors.purple;
      case 'Education':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showMonthYearPicker() async {
    final picked = await showMonthYearPicker(context);
    if (picked != null) {
      setState(() {
        selectedMonth = picked;
        touchedIndex = -1; // reset selection
      });
    }
  }

  Future<DateTime?> showMonthYearPicker(BuildContext context) {
    final now = DateTime.now();
    return showDialog<DateTime>(
      context: context,
      builder: (context) {
        int selectedYear = selectedMonth.year;
        int selectedMonthNum = selectedMonth.month;

        return AlertDialog(
          title: Text('Select Month and Year'),
          content: SizedBox(
            height: 150,
            child: Column(
              children: [
                DropdownButton<int>(
                  value: selectedYear,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedYear = val;
                      });
                    }
                  },
                  items: List.generate(
                      10,
                          (index) => DropdownMenuItem(
                          value: now.year - index, child: Text('${now.year - index}'))),
                ),
                DropdownButton<int>(
                  value: selectedMonthNum,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedMonthNum = val;
                      });
                    }
                  },
                  items: List.generate(
                      12,
                          (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                              '${DateTime(0, index + 1).month.toString().padLeft(2, '0')}'))),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('Cancel')),
            TextButton(
                onPressed: () =>
                    Navigator.pop(context, DateTime(selectedYear, selectedMonthNum)),
                child: Text('OK')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = getMonthlyExpenseByCategory();

    final filteredData = data.entries.where((e) => e.value > 0).toList();

    final total = filteredData.fold(0.0, (sum, e) => sum + e.value);

    String monthYearText =
        "${_monthName(selectedMonth.month)} ${selectedMonth.year}";

    return Scaffold(
      appBar: AppBar(title: Text("Expense Categories Overview")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month-year selector button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Showing for: ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _showMonthYearPicker,
                  icon: Icon(Icons.calendar_today),
                  label: Text(monthYearText,
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 50,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  final desiredIndex = pieTouchResponse
                                      ?.touchedSection?.touchedSectionIndex ??
                                      -1;
                                  touchedIndex = desiredIndex;
                                });
                              },
                            ),
                            sections: List.generate(filteredData.length, (i) {
                              final entry = filteredData[i];
                              final isTouched = i == touchedIndex;
                              final double fontSize = isTouched ? 18 : 14;
                              final double radius = isTouched ? 90 : 70;
                              final value = entry.value;
                              final percent = total > 0 ? (value / total * 100) : 0;

                              return PieChartSectionData(
                                color: _getCategoryColor(entry.key),
                                value: value,
                                title: isTouched
                                    ? '₹${value.toStringAsFixed(0)}\n${percent.toStringAsFixed(1)}%'
                                    : '',
                                radius: radius,
                                titleStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                titlePositionPercentageOffset: 0.6,
                              );
                            }),
                          ),
                        ),
                        if (touchedIndex != -1)
                          Positioned(
                            left: 0,
                            top: 10,
                            child: _buildTooltip(filteredData[touchedIndex], total),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Legend",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredData.length,
                              itemBuilder: (context, index) {
                                final entry = filteredData[index];
                                final percent =
                                total > 0 ? (entry.value / total * 100) : 0;
                                return Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(entry.key),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      Text(
                                        '₹${entry.value.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '(${percent.toStringAsFixed(1)}%)',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(MapEntry<String, double> entry, double total) {
    final percent = total > 0 ? (entry.value / total * 100) : 0;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        width: 160,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text('Amount: ₹${entry.value.toStringAsFixed(2)}'),
            Text('Percentage: ${percent.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}
