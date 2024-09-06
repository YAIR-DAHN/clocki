import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:clocki/screens/contact_us_screen.dart' as contactUs;
import 'package:clocki/screens/edit_alarm.dart';
import 'package:clocki/screens/report_issue_screen.dart' as reportIssue;
import 'package:clocki/screens/ring.dart';
import 'package:clocki/screens/troubleshooting_screen.dart';
import 'package:clocki/widgets/alarm_tile.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<AlarmGroup> alarmGroups;
  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    super.initState();
    if (Alarm.android) {
      checkAndroidNotificationPermission();
    }
    loadAlarms();
    subscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
  }

  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  void loadAlarms() {
    final alarms = Alarm.getAlarms();
    final groupMap = <String, AlarmGroup>{};

    for (final alarm in alarms) {
      final key = _getAlarmGroupKey(alarm);
      if (groupMap.containsKey(key)) {
        groupMap[key]!.alarms.add(alarm);
      } else {
        groupMap[key] = AlarmGroup(
          baseAlarm: alarm,
          alarms: [alarm],
          repeatingDays: _getRepeatingDays(alarm),
        );
      }
    }

    setState(() {
      alarmGroups = groupMap.values.toList();
      alarmGroups.sort((a, b) => a.baseAlarm.dateTime.isBefore(b.baseAlarm.dateTime) ? 0 : 1);
    });
  }

  String _getAlarmGroupKey(AlarmSettings alarm) {
    final parts = alarm.notificationBody.split('|');
    return '${alarm.dateTime.hour}:${alarm.dateTime.minute}|${parts.length > 1 ? parts[1] : ""}';
  }

  List<int> _getRepeatingDays(AlarmSettings alarm) {
    final parts = alarm.notificationBody.split('|');
    if (parts.length > 4) {
      return parts[4].split(',').where((s) => s.isNotEmpty).map(int.parse).toList();
    }
    return [];
  }

  String _getAlarmGroupSubtitle(AlarmGroup alarmGroup) {
    final parts = alarmGroup.baseAlarm.notificationBody.split('|');
    if (parts.length < 2) return 'התראה'; // אם אין מספיק מידע, נחזיר ערך ברירת מחדל

    final alarmMethod = parts[0].split(' ').last; // מקבל את החלק האחרון אחרי "זמן להתעורר!"
    final alarmName = alarmGroup.baseAlarm.notificationTitle; // שם ההתראה

    var subtitle = '';

    // הוסף את שם ההתראה אם הוא קיים
    if (alarmName.isNotEmpty && alarmName != 'התראה') {
      subtitle += '$alarmName\n';
    }

    // הוסף מידע על שיטת הכיבוי
    if (alarmMethod != 'standard') {
      subtitle += '${_getAlarmMethodText(alarmMethod, parts)}';
    }

    // הוסף מידע על ימים חוזרים
    if (alarmGroup.repeatingDays.isNotEmpty) {
      if (subtitle.isNotEmpty) subtitle += '\n';
      subtitle += '${_getRepeatingDaysText(alarmGroup.repeatingDays)}';
    }

    return subtitle;
  }

  String _getAlarmMethodText(String method, List<String> parts) {
    switch (method) {
      case 'text':
        return 'כיבוי על ידי הקלדת טקסט';
      case 'game':
        final game = parts[2];
        final score = parts[3];
        return 'כיבוי על ידי משחק $game (ניקוד נדרש: $score)';
      default:
        return 'כיבוי רגיל';
    }
  }

  String _getRepeatingDaysText(List<int> days) {
    if (days.isEmpty) return '';
    final daysOfWeek = ["א'", "ב'", "ג'", "ד'", "ה'", "ו'", "ש'"];
    final repeatingDays = days.map((day) => daysOfWeek[day]).join(' , ');
    return 'חוזר בימים: $repeatingDays';
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (context) => RingScreen(alarmSettings: alarmSettings),
      ),
    );
    if (result == true) {
      loadAlarms();
    }
  }

  Future<void> navigateToAlarmScreen(AlarmSettings? settings) async {
    final res = await showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: EditAlarmScreen(alarmSettings: settings),
        );
      },
    );

    if (res != null && res == true) loadAlarms();
  }

  Future<void> _toggleAlarmGroup(AlarmGroup alarmGroup, bool isActive) async {
    List<AlarmSettings> updatedAlarms = [];
    for (final alarm in alarmGroup.alarms) {
      if (isActive) {
        // בדיקה אם זמן ההתראה עדיין בעתיד
        if (alarm.dateTime.isAfter(DateTime.now())) {
          await Alarm.set(alarmSettings: alarm);
          updatedAlarms.add(alarm);
        } else {
          // אם הזמן עבר, נקבע את ההתראה ליום הבא באותה שעה
          final nextAlarmTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            alarm.dateTime.hour,
            alarm.dateTime.minute,
          ).add(const Duration(days: 1));
          final updatedAlarm = alarm.copyWith(dateTime: nextAlarmTime);
          await Alarm.set(alarmSettings: updatedAlarm);
          updatedAlarms.add(updatedAlarm);
        }
      } else {
        await Alarm.stop(alarm.id);
        updatedAlarms.add(alarm.copyWith(dateTime: alarm.dateTime.subtract(const Duration(days: 1))));
      }
    }
    
    final updatedAlarmGroup = AlarmGroup(
      baseAlarm: updatedAlarms.first,
      alarms: updatedAlarms,
      repeatingDays: alarmGroup.repeatingDays,
    );
    
    setState(() {
      alarmGroups[alarmGroups.indexWhere((group) => group.baseAlarm.id == alarmGroup.baseAlarm.id)] = updatedAlarmGroup;
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'קלוקי - שעון המעורר שלי',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 154, 45, 81),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'troubleshoot':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TroubleshootingScreen()),
                  );
                case 'contact':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const contactUs.ContactUsScreen()),
                  );
                case 'report':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const reportIssue.ContactUsScreen()),
                  );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'troubleshoot',
                child: Text('פתרון בעיות'),
              ),
              const PopupMenuItem<String>(
                value: 'contact',
                child: Text('צור קשר'),
              ),
              // const PopupMenuItem<String>(
              //   value: 'report',
              //   child: Text('דיווח על בעיה'),
              // ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(110, 255, 64, 128), Color.fromARGB(255, 244, 239, 238)],
          ),
        ),
        child: SafeArea(
          child: alarmGroups.isNotEmpty
              ? ListView.builder(
                  itemCount: alarmGroups.length,
                  itemBuilder: (context, index) {
                    final alarmGroup = alarmGroups[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Dismissible(
                          key: Key(alarmGroup.baseAlarm.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: Icon(Icons.delete, color: Colors.white, size: 32),
                            ),
                          ),
                          onDismissed: (direction) {
                            for (final alarm in alarmGroup.alarms) {
                              Alarm.stop(alarm.id);
                            }
                            loadAlarms();
                          },
                          child: AlarmTile(
                            title: TimeOfDay.fromDateTime(alarmGroup.baseAlarm.dateTime).format(context),
                            subtitle: _getAlarmGroupSubtitle(alarmGroup),
                            isActive: alarmGroup.alarms.any((alarm) => alarm.dateTime.isAfter(DateTime.now())),
                            onPressed: () => navigateToAlarmScreen(alarmGroup.baseAlarm),
                            onToggle: (bool value) => _toggleAlarmGroup(alarmGroup, value),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off, size: 120, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(height: 24),
                      Text(
                        'אין התראות מוגדרות',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => navigateToAlarmScreen(null),
        elevation: 8,
        icon: const Icon(Icons.add_alarm),
        label: const Text('הוסף התראה'),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class AlarmGroup {

  AlarmGroup({
    required this.baseAlarm,
    required this.alarms,
    required this.repeatingDays,
  });
  final AlarmSettings baseAlarm;
  final List<AlarmSettings> alarms;
  final List<int> repeatingDays;
}