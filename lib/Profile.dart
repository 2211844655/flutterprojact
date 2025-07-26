import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double currentGoal = 3.0;
  double newGoal = 2.5;
  int selectedPreset = 2;
  bool notificationsEnabled = true;

  int reminderIntervalValue = 10;
  String reminderIntervalUnit = 'seconds';

  final TextEditingController _goalController =
  TextEditingController(text: '2.5');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (notificationsEnabled) {
      _scheduleReminderNotification();
    }
  }

  Future<void> _scheduleReminderNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'water_reminder_channel',
        'Water Reminder',
        channelDescription: 'Channel for water reminders',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    Duration interval;
    if (reminderIntervalUnit == 'seconds') {
      interval = Duration(seconds: reminderIntervalValue);
    } else if (reminderIntervalUnit == 'minutes') {
      interval = Duration(minutes: reminderIntervalValue);
    } else {
      interval = Duration(hours: reminderIntervalValue);
    }

    final now = tz.TZDateTime.now(tz.local);
    final firstNotificationTime = now.add(interval);

    for (int i = 0; i < 24; i++) {
      final scheduledTime = firstNotificationTime.add(interval * i);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        i,
        '📢 تذكير: اشرب الماء 💧',
        'حافظ على صحتك بشرب الماء بانتظام',
        scheduledTime,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> _cancelNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _applyPreset(double goal, int index) {
    setState(() {
      newGoal = goal;
      selectedPreset = index;
      _goalController.text = goal.toStringAsFixed(1);
    });
  }

  void _resetSettings() {
    setState(() {
      newGoal = currentGoal;
      selectedPreset = 2;
      notificationsEnabled = true;
      reminderIntervalValue = 10;
      reminderIntervalUnit = 'seconds';
      _goalController.text = currentGoal.toStringAsFixed(1);
    });
    _scheduleReminderNotification();
  }

  void _saveGoal() {
    setState(() {
      currentGoal = newGoal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 35)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Daily Goal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade100),
                borderRadius: BorderRadius.circular(16),
                color: Colors.green.shade50,
              ),
              child: Row(
                children: [
                  const Icon(Icons.track_changes, color: Colors.green),
                  const SizedBox(width: 12),
                  Text('${currentGoal.toStringAsFixed(1)}L',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Text('Current target'),
                  const Spacer(),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Active',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('Adjust Goal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 180,
                child: TextFormField(
                  controller: _goalController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.water_drop_outlined),
                    labelText: 'Goal (Liters)',
                    labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed >= 0.5 && parsed <= 5.0) {
                      setState(() {
                        newGoal = parsed;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                '🔔 Recommended: 2-3 liters daily for optimal hydration',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            const Text('Quick Presets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Column(
              children: [
                _presetTile('Light Activity', 1.5, 0, Colors.blue.shade100),
                _presetTile(
                    'Moderate Activity', 2.0, 1, Colors.green.shade100),
                _presetTile(
                    'Active Lifestyle', 2.5, 2, Colors.orange.shade100),
                _presetTile('High Performance', 3.0, 3, Colors.red.shade100),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Reminder Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Remind me to drink water'),
              value: notificationsEnabled,
              onChanged: (val) {
                setState(() {
                  notificationsEnabled = val;
                });
                if (val) {
                  _scheduleReminderNotification();
                } else {
                  _cancelNotifications();
                }
              },
              secondary: const Icon(Icons.notifications),
            ),
            if (notificationsEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: reminderIntervalValue.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            setState(() {
                              reminderIntervalValue = parsed;
                            });
                            _scheduleReminderNotification();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: reminderIntervalUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: ['seconds', 'minutes', 'hours'].map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit[0].toUpperCase() + unit.substring(1)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              reminderIntervalUnit = value;
                            });
                            _scheduleReminderNotification();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveGoal,
                    child: const Text('Save Goal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetSettings,
                    child: const Text('Reset Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetTile(String label, double value, int index, Color color) {
    return GestureDetector(
      onTap: () => _applyPreset(value, index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selectedPreset == index
              ? color.withOpacity(0.5)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selectedPreset == index ? color : Colors.transparent,
              width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.water_drop,
                color: selectedPreset == index ? Colors.black : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("${value}L daily",
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            if (selectedPreset == index)
              const Icon(Icons.radio_button_checked, color: Colors.blue)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}
