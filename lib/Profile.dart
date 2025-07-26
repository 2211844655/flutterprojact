import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double currentGoal = 3.0;
  double newGoal = 2.5;
  int selectedPreset = 2;
  bool notificationsEnabled = false;

  int reminderIntervalValue = 10;
  String reminderIntervalUnit = 'seconds';

  final TextEditingController _goalController = TextEditingController(text: '2.5');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _customNotificationTimer;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _requestNotificationPermission();
    _initializeNotifications();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    print('Notification permission status: $status');
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Water Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  void _startCustomNotification(Duration interval) {
    _customNotificationTimer?.cancel();
    _customNotificationTimer = Timer.periodic(interval, (timer) {
      _showNotification('💧 تذكير شرب الماء', 'حان وقت شرب الماء!');
    });
  }

  void _stopCustomNotification() {
    _customNotificationTimer?.cancel();
    _customNotificationTimer = null;
  }

  Duration? _getDurationFromInput() {
    if (reminderIntervalValue <= 0) return null;

    switch (reminderIntervalUnit) {
      case 'seconds':
        return Duration(seconds: reminderIntervalValue);
      case 'minutes':
        return Duration(minutes: reminderIntervalValue);
      case 'hours':
        return Duration(hours: reminderIntervalValue);
      default:
        return null;
    }
  }

  void _toggleNotifications() {
    if (notificationsEnabled) {
      _stopCustomNotification();
      setState(() {
        notificationsEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إيقاف التذكيرات')),
      );
    } else {
      final duration = _getDurationFromInput();
      if (duration != null) {
        _startCustomNotification(duration);
        setState(() {
          notificationsEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تفعيل التذكير كل $reminderIntervalValue ${_getDisplayUnit(reminderIntervalUnit)}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال مدة صالحة')),
        );
      }
    }
  }

  String _getDisplayUnit(String unit) {
    switch (unit) {
      case 'seconds':
        return 'ثواني';
      case 'minutes':
        return 'دقائق';
      case 'hours':
        return 'ساعات';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    _customNotificationTimer?.cancel();
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
      notificationsEnabled = false;
      reminderIntervalValue = 10;
      reminderIntervalUnit = 'seconds';
      _goalController.text = currentGoal.toStringAsFixed(1);
    });
    _stopCustomNotification();
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.water_drop_outlined),
                    labelText: 'Goal (Liters)',
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                _presetTile('Moderate Activity', 2.0, 1, Colors.green.shade100),
                _presetTile('Active Lifestyle', 2.5, 2, Colors.orange.shade100),
                _presetTile('High Performance', 3.0, 3, Colors.red.shade100),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Reminder Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
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
                        if (notificationsEnabled) {
                          _toggleNotifications();
                          _toggleNotifications();
                        }
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
                        if (notificationsEnabled) {
                          _toggleNotifications();
                          _toggleNotifications();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(notificationsEnabled
                    ? Icons.notifications_off
                    : Icons.notifications_active),
                label: Text(notificationsEnabled
                    ? 'إيقاف التذكيرات'
                    : 'تشغيل التذكيرات'),
                onPressed: _toggleNotifications,
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
