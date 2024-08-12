import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'edit_alarm.dart';
import 'ring.dart';
import '../widgets/alarm_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<AlarmSettings> alarms;

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
    setState(() {
      alarms = Alarm.getAlarms();
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
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

  void _toggleAlarm(AlarmSettings alarm, bool isActive) async {
    if (isActive) {
      await Alarm.set(alarmSettings: alarm);
    } else {
      await Alarm.stop(alarm.id);
    }
    loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('שעון מעורר חכם', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
        elevation: 0,
      ),
      body: SafeArea(
        child: alarms.isNotEmpty
            ? ListView.builder(
                itemCount: alarms.length,
                itemBuilder: (context, index) {
                  final alarm = alarms[index];
                  return AlarmTile(
                    key: Key(alarm.id.toString()),
                    title: TimeOfDay.fromDateTime(alarm.dateTime).format(context),
                    subtitle: _getAlarmSubtitle(alarm),
                    isActive: alarm.dateTime.isAfter(DateTime.now()),
                    onPressed: () => navigateToAlarmScreen(alarm),
                    onToggle: (bool value) => _toggleAlarm(alarm, value),
                    onDismissed: () {
                      Alarm.stop(alarm.id).then((_) => loadAlarms());
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
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

  String _getAlarmSubtitle(AlarmSettings alarm) {
    // TODO: Implement this method to return a string describing the alarm
    // (e.g., "כל יום", "חד פעמי", וכו')
    return "חד פעמי";
  }
}