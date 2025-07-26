import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double todayTotal = 2.3;
  final double goal = 3.0;
  final int daysToShow = 14;

  final Map<String, List<Map<String, String>>> dailyLogs = {
    '2025-07-24': [
      {'amount': '+250ml', 'time': '08:00 AM'},
      {'amount': '+500ml', 'time': '12:00 PM'},
    ],
    '2025-07-25': [
      {'amount': '+250ml', 'time': '09:00 AM'},
    ],
    '2025-07-23': [
      {'amount': '+1.0L', 'time': '10:00 AM'},
      {'amount': '+250ml', 'time': '01:00 PM'},
    ],
    '2025-07-22': [
      {'amount': '+500ml', 'time': '07:00 AM'},
      {'amount': '+250ml', 'time': '10:00 AM'},
    ],
    '2025-07-20': [],
    '2025-07-19': [
      {'amount': '+1.0L', 'time': '09:00 AM'},
      {'amount': '+500ml', 'time': '02:00 PM'},
    ],
    '2025-07-18': [
      {'amount': '+250ml', 'time': '11:00 AM'},
    ],
  };

  late String selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDay = DateFormat('yyyy-MM-dd').format(now);
  }

  void _removeLogEntry(int index) {
    setState(() {
      if (dailyLogs[selectedDay] != null && dailyLogs[selectedDay]!.isNotEmpty) {
        String amountStr = dailyLogs[selectedDay]![index]['amount'] ?? '';
        double amountValue = _parseAmount(amountStr);
        todayTotal = (todayTotal - amountValue).clamp(0, double.infinity);
        dailyLogs[selectedDay]!.removeAt(index);
      }
    });
  }

  double _parseAmount(String amount) {
    try {
      String clean = amount.replaceAll('+', '').toLowerCase();
      if (clean.endsWith('ml')) {
        String numStr = clean.replaceAll('ml', '').trim();
        return double.parse(numStr) / 1000.0;
      } else if (clean.endsWith('l')) {
        String numStr = clean.replaceAll('l', '').trim();
        return double.parse(numStr);
      }
    } catch (_) {}
    return 0;
  }

  double _calculateTotal(String date) {
    final logs = dailyLogs[date] ?? [];
    return logs.fold(0.0, (sum, item) => sum + _parseAmount(item['amount']!));
  }

  void _showDayDetails(String date) {
    final logs = dailyLogs[date] ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$date Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: logs.map((entry) => ListTile(
            title: Text(entry['amount']!),
            subtitle: Text(entry['time']!),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          )
        ],
      ),
    );
  }

  List<String> _generateLastDates(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final date = now.subtract(Duration(days: i));
      return DateFormat('yyyy-MM-dd').format(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = (todayTotal / goal).clamp(0, 1);
    final isToday = selectedDay == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Analytics',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 35)),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Track your hydration patterns',
                  style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.water_drop, color: Colors.blue),
                          SizedBox(height: 8),
                          Text('${todayTotal.toStringAsFixed(1)}L',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text("Today's Total"),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.blue[100],
                            color: Colors.blue,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Text("Today's Water Log",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: (dailyLogs[selectedDay] ?? [])
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final log = entry.value;
                    return ListTile(
                      leading: Icon(Icons.water_drop, color: Colors.blue),
                      title: Text(log['amount']!),
                      subtitle: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(log['time']!),
                        ],
                      ),
                      trailing: isToday
                          ? IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _removeLogEntry(index);
                        },
                      )
                          : null,
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 30),
              Text("History",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 10),
              ..._generateLastDates(daysToShow).map((date) {
                double total = _calculateTotal(date);
                bool reached = total >= goal;
                return Card(
                  child: ListTile(
                    leading: Icon(reached ? Icons.check : Icons.close,
                        color: reached ? Colors.green : Colors.red),
                    title: Text(date),
                    subtitle: Text('Total: ${total.toStringAsFixed(2)} L'),
                    trailing: Text(reached ? 'Goal Met' : 'Not Met'),
                    onTap: () => _showDayDetails(date),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
