import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final double todayTotal = 2.3;
  final double goal = 3.0;

  final Map<String, double> weeklyData = {
    'Mon': 0.85,
    'Tue': 0.92,
    'Wed': 0.78,
    'Thu': 0.95,
    'Fri': 0.88,
    'Sat': 1.0,
    'Sun': 0.75,
  };

  final Map<String, List<Map<String, String>>> dailyLogs = {
    'Mon': [
      {'amount': '+250ml', 'time': '08:00 AM'},
      {'amount': '+500ml', 'time': '12:00 PM'},
    ],
    'Tue': [
      {'amount': '+250ml', 'time': '09:00 AM'},
    ],
    'Wed': [
      {'amount': '+1.0L', 'time': '10:00 AM'},
      {'amount': '+250ml', 'time': '01:00 PM'},
    ],
    'Thu': [
      {'amount': '+500ml', 'time': '07:00 AM'},
      {'amount': '+250ml', 'time': '10:00 AM'},
    ],
    'Fri': [],
    'Sat': [
      {'amount': '+1.0L', 'time': '09:00 AM'},
      {'amount': '+500ml', 'time': '02:00 PM'},
    ],
    'Sun': [
      {'amount': '+250ml', 'time': '11:00 AM'},
    ],
  };

  late final String todayLabel;


  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    todayLabel = _getDayLabel(now.weekday);
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
      default:
        return 'Sun';
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (todayTotal / goal).clamp(0, 1);
    final isToday = todayLabel == _getDayLabel(DateTime.now().weekday);

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            minHeight:8,
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
              Text('Weekly Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weeklyData.entries.map((entry) {
                  return Column(
                    children: [
                      Container(
                        width: 20,
                        height: 80,
                        decoration: BoxDecoration(
                          color: entry.key == 'Sun'
                              ? Colors.blue
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 80 * entry.value,
                            width: 20,
                            decoration: BoxDecoration(
                              color: entry.key == 'Sun'
                                  ? Colors.blue.shade900
                                  : Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(entry.key),
                      Text('${(entry.value * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12))
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 30),

              Text("Daily Water Log",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 12),
              // SizedBox(
              //   height: 50,
              //   child: ListView(
              //     scrollDirection: Axis.horizontal,
              //     children: dailyLogs.keys.map((day) {
              //       final isSelected = day == selectedDay;
              //       return GestureDetector(
              //         onTap: () {
              //           setState(() {
              //             selectedDay = day;
              //           });
              //         },
              //         child: Container(
              //           margin: EdgeInsets.symmetric(horizontal: 6),
              //           padding:
              //           EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              //           decoration: BoxDecoration(
              //             color:
              //             isSelected ? Colors.blue : Colors.grey.shade300,
              //             borderRadius: BorderRadius.circular(20),
              //           ),
              //           child: Center(
              //             child: Text(day,
              //                 style: TextStyle(
              //                   color:
              //                   isSelected ? Colors.white : Colors.black87,
              //                   fontWeight: FontWeight.bold,
              //                 )),
              //           ),
              //         ),
              //       );
              //     }).toList(),
              //   ),
              // ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: (dailyLogs[todayLabel] ?? [])
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
                          setState(() {
                            dailyLogs[todayLabel]!.removeAt(index);
                          });
                        },
                      )
                          : null,
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 30),
              Text("Insights",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.purple),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Best Hydration Day',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                              "You're most consistent on Saturdays with an average of 2.3L"),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
