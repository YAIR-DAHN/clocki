import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'edit_alarm.dart';
import 'ring.dart';
import '../widgets/alarm_tile.dart';
import 'troubleshooting_screen.dart';

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
    if (parts.length > 6) {
      return parts[6].split(',').map((e) => int.parse(e)).toList();
    }
    return [];
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
      shape: RoundedRectangleBorder(
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

  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('שעון מעורר חכם',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white)),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'troubleshoot') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TroubleshootingScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'troubleshoot',
                child: Text('פתרון בעיות'),
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
                    Icon(Icons.alarm_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'אין התראות מוגדרות',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToAlarmScreen(null),
        child: Icon(Icons.add),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getAlarmGroupSubtitle(AlarmGroup alarmGroup) {
    final parts = alarmGroup.baseAlarm.notificationBody.split('|');
    final alarmName = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : "התראה";
    
    if (alarmGroup.repeatingDays.isEmpty) {
      return alarmName;
    }

    final daysOfWeek = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'];
    final repeatingDays = alarmGroup.repeatingDays.map((day) => daysOfWeek[day]).join(', ');
    return '$alarmName\nחוזר בימים: $repeatingDays';
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