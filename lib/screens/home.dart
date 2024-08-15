import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'edit_alarm.dart';
import 'ring.dart';
import '../widgets/alarm_tile.dart';
import 'troubleshooting_screen.dart';
import 'contact_us_screen.dart' as contactUs;
import 'report_issue_screen.dart' as reportIssue;

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
    final List<AlarmSettings> alarms = Alarm.getAlarms();
    final Map<String, AlarmGroup> groupMap = {};

    for (var alarm in alarms) {
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
      return parts[4].split(',').where((s) => s.isNotEmpty).map((e) => int.parse(e)).toList();
    }
    return [];
  }

  String _getAlarmGroupSubtitle(AlarmGroup alarmGroup) {
    final parts = alarmGroup.baseAlarm.notificationBody.split('|');
    if (parts.length < 2) return "התראה"; // אם אין מספיק מידע, נחזיר ערך ברירת מחדל

    final alarmMethod = parts[0].split(' ').last; // מקבל את החלק האחרון אחרי "זמן להתעורר!"
    final alarmName = parts[1].isNotEmpty ? parts[1] : "התראה";

    String subtitle = alarmName;

    if (alarmMethod != 'standard') {
      subtitle += ' - ${_getAlarmMethodText(alarmMethod, parts)}';
    }

    if (alarmGroup.repeatingDays.isNotEmpty) {
      subtitle += '\n${_getRepeatingDaysText(alarmGroup.repeatingDays)}';
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
    final repeatingDays = days.map((day) => daysOfWeek[day]).join(" , ");
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

  void _toggleAlarmGroup(AlarmGroup alarmGroup, bool isActive) async {
    for (var alarm in alarmGroup.alarms) {
      if (isActive) {
        await Alarm.set(alarmSettings: alarm);
      } else {
        await Alarm.stop(alarm.id);
      }
    }
    loadAlarms();
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
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'troubleshoot':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TroubleshootingScreen()),
                  );
                  break;
                case 'contact':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => contactUs.ContactUsScreen()),
                  );
                  break;
                case 'report':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => reportIssue.ContactUsScreen()),
                  );
                  break;
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
              const PopupMenuItem<String>(
                value: 'report',
                child: Text('דיווח על בעיה'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: alarmGroups.isNotEmpty
            ? ListView.builder(
                itemCount: alarmGroups.length,
                itemBuilder: (context, index) {
                  final alarmGroup = alarmGroups[index];
                  return AlarmTile(
                    key: Key(alarmGroup.baseAlarm.id.toString()),
                    title: TimeOfDay.fromDateTime(alarmGroup.baseAlarm.dateTime).format(context),
                    subtitle: _getAlarmGroupSubtitle(alarmGroup),
                    isActive: alarmGroup.alarms.any((alarm) => alarm.dateTime.isAfter(DateTime.now())),
                    onPressed: () => navigateToAlarmScreen(alarmGroup.baseAlarm),
                    onToggle: (bool value) => _toggleAlarmGroup(alarmGroup, value),
                    onDismissed: () {
                      for (var alarm in alarmGroup.alarms) {
                        Alarm.stop(alarm.id);
                      }
                      loadAlarms();
                    },
                  );
                },
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.alarm_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'אין התראות מוגדרות',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToAlarmScreen(null),
        child: const Icon(Icons.add),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class AlarmGroup {
  final AlarmSettings baseAlarm;
  final List<AlarmSettings> alarms;
  final List<int> repeatingDays;

  AlarmGroup({
    required this.baseAlarm,
    required this.alarms,
    required this.repeatingDays,
  });
}