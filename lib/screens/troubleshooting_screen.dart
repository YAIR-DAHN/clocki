import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class TroubleshootingScreen extends StatefulWidget {
  @override
  _TroubleshootingScreenState createState() => _TroubleshootingScreenState();
}

class _TroubleshootingScreenState extends State<TroubleshootingScreen> {
  bool _isBackgroundPermissionGranted = false;
  bool _isBatteryOptimizationDisabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final backgroundStatus = await Permission.ignoreBatteryOptimizations.status;
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    
    if (androidInfo.version.sdkInt >= 23) {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      setState(() {
        _isBatteryOptimizationDisabled = batteryStatus.isGranted;
      });
    }

    setState(() {
      _isBackgroundPermissionGranted = backgroundStatus.isGranted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('פתרון בעיות'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('הרשאת פעולה ברקע'),
            subtitle: Text('נדרש כדי שהאפליקציה תוכל להפעיל התראות'),
            trailing: _isBackgroundPermissionGranted
                ? Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    child: Text('אפשר'),
                    onPressed: () => _requestBackgroundPermission(),
                  ),
          ),
          ListTile(
            title: Text('ביטול אופטימיזציית סוללה'),
            subtitle: Text('נדרש לפעולה אמינה של התראות'),
            trailing: _isBatteryOptimizationDisabled
                ? Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    child: Text('הגדר'),
                    onPressed: () => _openBatteryOptimizationSettings(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestBackgroundPermission() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    setState(() {
      _isBackgroundPermissionGranted = status.isGranted;
    });
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ההרשאה התקבלה בהצלחה')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('נא לאשר את ההרשאה בהגדרות המכשיר')),
      );
    }
  }

  Future<void> _openBatteryOptimizationSettings() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
  
    if (androidInfo.version.sdkInt >= 23) {
      const platform = MethodChannel('com.gdelataillade.alarm.alarm_example/app_settings');
      try {
        await platform.invokeMethod('openBatteryOptimizationSettings');
        // עדכון מצב ההרשאה לאחר שהמשתמש חוזר מההגדרות
        await Future.delayed(Duration(seconds: 1));
        await _checkPermissions();
      } on PlatformException catch (e) {
        print("Failed to open battery optimization settings: '${e.message}'.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא ניתן לפתוח את הגדרות אופטימיזציית הסוללה')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('אופטימיזציית סוללה אינה רלוונטית לגרסת המכשיר שלך')),
      );
    }
  }
}