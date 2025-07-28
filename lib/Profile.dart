import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// استخدام prefs كمتغير عام من main.dart
import 'main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double currentGoal = 3.0;
  double newGoal = 3.0; // لتعديل الهدف قبل الحفظ
  int selectedPreset = 2; // Default to 'Active Lifestyle'
  bool notificationsEnabled = false;

  int reminderIntervalValue = 10;
  String reminderIntervalUnit = 'seconds';

  late TextEditingController _goalController;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _customNotificationTimer;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(text: currentGoal.toStringAsFixed(1));
    tz.initializeTimeZones();
    _requestNotificationPermission();
    _initializeNotifications();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    currentGoal = prefs.getDouble('dailyGoal') ?? 3.0;
    newGoal = currentGoal; // قم بتحديث newGoal أيضًا
    _goalController.text = currentGoal.toStringAsFixed(1);

    notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
    reminderIntervalValue = prefs.getInt('reminderIntervalValue') ?? 10;
    reminderIntervalUnit = prefs.getString('reminderIntervalUnit') ?? 'seconds';

    setState(() {
      // بعد تحميل البيانات، قم بتحديث selectedPreset بناءً على currentGoal
      if (currentGoal == 1.5) {
        selectedPreset = 0;
      } else if (currentGoal == 2.0) {
        selectedPreset = 1;
      } else if (currentGoal == 2.5) {
        selectedPreset = 2;
      } else if (currentGoal == 3.0) {
        selectedPreset = 3;
      } else {
        selectedPreset = -1; // لا يوجد preset مطابق
      }

      if (notificationsEnabled) {
        final duration = _getDurationFromInput();
        if (duration != null) {
          _startCustomNotification(duration);
        }
      }
    });
  }

  Future<void> _saveSettings() async {
    await prefs.setDouble('dailyGoal', currentGoal);
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setInt('reminderIntervalValue', reminderIntervalValue);
    await prefs.setString('reminderIntervalUnit', reminderIntervalUnit);
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
      channelDescription: 'Channel for water intake reminders',
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
      _saveSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications are disabled')),
      );
    } else {
      final duration = _getDurationFromInput();
      if (duration != null) {
        _startCustomNotification(duration);
        setState(() {
          notificationsEnabled = true;
        });
        _saveSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder activated every $reminderIntervalValue ${_getDisplayUnit(reminderIntervalUnit)}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid period')),
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
      currentGoal = 3.0; // تعيين الافتراضي
      newGoal = currentGoal;
      selectedPreset = 2; // يعود إلى Active Lifestyle
      notificationsEnabled = false;
      reminderIntervalValue = 10;
      reminderIntervalUnit = 'seconds';
      _goalController.text = currentGoal.toStringAsFixed(1);
    });
    _stopCustomNotification();
    _saveSettings(); // حفظ الإعدادات الافتراضية
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings have been reset to default.')),
    );
  }

  void _saveGoal() {
    setState(() {
      currentGoal = newGoal;
    });
    _saveSettings(); // حفظ الهدف الجديد
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Daily goal saved: ${currentGoal.toStringAsFixed(1)}L')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Profile', // تم تصحيح الاسم هنا
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
                        selectedPreset = -1; // إلغاء تحديد الـ preset إذا تم التعديل يدويًا
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
                        // إذا كانت الإشعارات مفعلة، أعد تفعيلها بالفاصل الزمني الجديد
                        if (notificationsEnabled) {
                          _stopCustomNotification();
                          final duration = _getDurationFromInput();
                          if (duration != null) {
                            _startCustomNotification(duration);
                          }
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
                        // إذا كانت الإشعارات مفعلة، أعد تفعيلها بالفاصل الزمني الجديد
                        if (notificationsEnabled) {
                          _stopCustomNotification();
                          final duration = _getDurationFromInput();
                          if (duration != null) {
                            _startCustomNotification(duration);
                          }
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
                    ? 'Stop notification'
                    : 'Activate notifications'),
                onPressed: _toggleNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: notificationsEnabled ? Colors.red.shade400 : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveGoal,
                    child: const Text('Save Goal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetSettings,
                    child: const Text('Reset Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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