import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// استخدام prefs كمتغير عام من main.dart
import 'main.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double currentWater = 0;
  double goal = 3.0; // سيتم تحميله من SharedPreferences
  bool goalReachedNotified = false;

  final TextEditingController _customController = TextEditingController();

  Map<String, List<Map<String, String>>> dailyLogs = {};
  Map<String, double> dailyGoals = {}; // تم إضافة هذه الخريطة لحفظ الهدف لكل يوم

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // تحميل الهدف الحالي
    goal = prefs.getDouble('dailyGoal') ?? 3.0;

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
    }

    // تحميل الأهداف اليومية المحفوظة
    final String? savedDailyGoalsJson = prefs.getString('dailyGoals');
    if (savedDailyGoalsJson != null) {
      dailyGoals = Map<String, double>.from(
        (json.decode(savedDailyGoalsJson) as Map).map((key, value) => MapEntry(key, value as double)),
      );
    }

    currentWater = _calculateTotal(DateFormat('yyyy-MM-dd').format(DateTime.now())); // حساب الإجمالي لليوم الحالي من السجلات المحفوظة
    setState(() {});
  }

  double _calculateTotal(String date) {
    final logs = dailyLogs[date] ?? [];
    return logs.fold(0.0, (sum, item) => sum + _parseAmount(item['amount']!));
  }

  Future<void> _saveData() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // حفظ الهدف الحالي لليوم
    dailyGoals[today] = goal; // هنا يتم حفظ الهدف الخاص باليوم الحالي

    final logsJson = json.encode(dailyLogs);
    final dailyGoalsJson = json.encode(dailyGoals); // تحويل الأهداف إلى JSON
    await prefs.setString('dailyLogs', logsJson);
    await prefs.setString('dailyGoals', dailyGoalsJson); // حفظ الأهداف
    await prefs.setDouble('currentWater_$today', currentWater); // حفظ إجمالي اليوم بشكل منفصل
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

  void addWater(double amount) {
    setState(() {
      currentWater += amount;
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final time = DateFormat('hh:mm a').format(now);

      if (!dailyLogs.containsKey(today)) {
        dailyLogs[today] = [];
      }
      dailyLogs[today]!.add({'amount': '+${amount * 1000}ml', 'time': time});

      _saveData(); // هنا يتم استدعاء حفظ البيانات بما في ذلك الهدف اليومي

      double progress = (currentWater / goal).clamp(0, 1);

      if (progress >= 1.0 && !goalReachedNotified) {
        goalReachedNotified = true;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("🎉 Congrats!"),
            content: Text("You have reached your daily goal of ${goal}L!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              )
            ],
          ),
        );
      }
    });
  }

  Color getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.75) return Colors.blueAccent;
    if (progress >= 0.25) return Colors.lightBlue;
    return Colors.lightBlueAccent;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = (currentWater / goal).clamp(0, 1);
    Color color = getProgressColor(progress);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Water', style: TextStyle(fontWeight: FontWeight.bold ,color: Colors.white,fontSize: 35)),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 450,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: AssetImage('images/Untitled-1.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                  CircularPercentIndicator(
                    radius: 85.0,
                    lineWidth: 15.0,
                    animationDuration: 1000,
                    percent: progress,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: color,
                    backgroundColor: Colors.white30,
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop, color: Colors.blue, size: 28),
                        SizedBox(height: 4),
                        Text('${currentWater.toStringAsFixed(1)}L',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text('of ${goal}L', style: TextStyle(color: Colors.black54)),
                        SizedBox(height: 4),
                        Text('${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text("\u{1F4AA} Almost there! Keep going!",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            SizedBox(height: 30),
            Text('Quick Add', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                drinkCard('Glass', 250, Colors.blue, Icons.local_drink, () => addWater(0.25)),
                drinkCard('Bottle', 500, Colors.green, Icons.local_drink_outlined, () => addWater(0.5)),
                drinkCard('Large', 1000, Colors.orange, Icons.liquor, () => addWater(1.0)),
              ],
            ),
            SizedBox(height: 30),
            Text('Or enter custom amount (ml)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter amount in ml',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 19),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_customController.text.isNotEmpty) {
                      double? value = double.tryParse(_customController.text);
                      if (value != null && value > 0) {
                        addWater(value / 1000); // نحوله من ml إلى L
                        _customController.clear();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a valid number')),
                        );
                      }
                    }
                  },
                  child: Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget drinkCard(String label, int ml, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 140,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(height: 6),
            Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 20)),
            SizedBox(height: 4),
            Text('$ml ml', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}