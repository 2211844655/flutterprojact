import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// استخدام prefs كمتغير عام من main.dart
import 'main.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double todayTotal = 0.0; // سيتم حسابه من dailyLogs
  double currentDailyGoal = 3.0; // الهدف الحالي، سيتم تحميله من SharedPreferences
  final int daysToShow = 14;

  Map<String, List<Map<String, String>>> dailyLogs = {};
  Map<String, double> dailyGoals = {}; // لتخزين الهدف لكل يوم
  late String selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDay = DateFormat('yyyy-MM-dd').format(now);
    _loadData();
  }

  Future<void> _loadData() async {
    // تحميل الهدف الحالي
    currentDailyGoal = prefs.getDouble('dailyGoal') ?? 3.0;

    // تحميل جميع سجلات المياه
    final String? savedLogsJson = prefs.getString('dailyLogs');
    if (savedLogsJson != null) {
      dailyLogs = Map<String, List<Map<String, String>>>.from(
        (json.decode(savedLogsJson) as Map).map((key, value) => MapEntry(
            key,
            (value as List)
                .map((item) => Map<String, String>.from(item))
                .toList())),
      );
    } else {
      dailyLogs = {}; // تهيئة الخريطة فارغة إذا لم يكن هناك سجلات
    }

    // تحميل الأهداف اليومية المحفوظة
    final String? savedDailyGoalsJson = prefs.getString('dailyGoals');
    if (savedDailyGoalsJson != null) {
      dailyGoals = Map<String, double>.from(
        (json.decode(savedDailyGoalsJson) as Map).map((key, value) => MapEntry(key, value as double)),
      );
    } else {
      dailyGoals = {}; // تهيئة الخريطة فارغة إذا لم يكن هناك أهداف
    }

    todayTotal = _calculateTotal(selectedDay); // حساب الإجمالي لليوم المحدد

    setState(() {});
  }

  Future<void> _saveData() async {
    final logsJson = json.encode(dailyLogs);
    await prefs.setString('dailyLogs', logsJson);
    final dailyGoalsJson = json.encode(dailyGoals);
    await prefs.setString('dailyGoals', dailyGoalsJson);
  }

  void _removeLogEntry(int index) {
    setState(() {
      if (dailyLogs[selectedDay] != null && dailyLogs[selectedDay]!.isNotEmpty) {
        String amountStr = dailyLogs[selectedDay]![index]['amount'] ?? '';
        double amountValue = _parseAmount(amountStr);
        dailyLogs[selectedDay]!.removeAt(index);
        todayTotal = (todayTotal - amountValue).clamp(0, double.infinity); // تحديث الإجمالي

        _saveData(); // حفظ التغييرات بعد الحذف
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

  List<String> _generateLastDates(int count) {
    final now = DateTime.now();
    List<String> dates = [];
    for (int i = 0; i < count; i++) {
      final date = now.subtract(Duration(days: i));
      dates.add(DateFormat('yyyy-MM-dd').format(date));
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    double progress = (todayTotal / currentDailyGoal).clamp(0, 1);
    final isToday = selectedDay == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Analytics',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 35)),
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
              Column(
                children: _generateLastDates(daysToShow).map((date) {
                  double total = _calculateTotal(date);
                  // استخدم الهدف المحفوظ لذلك اليوم، وإلا استخدم الهدف الحالي كافتراضي
                  double dayGoal = dailyGoals[date] ?? currentDailyGoal;
                  bool reached = total >= dayGoal;
                  List<Map<String, String>> logs = dailyLogs[date] ?? [];

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      leading: Icon(reached ? Icons.check : Icons.close,
                          color: reached ? Colors.green : Colors.red),
                      title: Text(DateFormat('yyyy-MM-dd')
                          .format(DateTime.parse(date))),
                      subtitle:
                      Text('Total: ${total.toStringAsFixed(2)} L / Goal: ${dayGoal.toStringAsFixed(1)} L'),
                      children: logs.isEmpty
                          ? [
                        ListTile(
                          title: Text(
                            'No logs for this day.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      ]
                          : logs.map((log) {
                        return ListTile(
                          leading: Icon(Icons.water_drop,
                              color: Colors.blue),
                          title: Text(log['amount']!),
                          subtitle: Text(log['time']!),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}