import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class TroubleshootingScreen extends StatefulWidget {
  const TroubleshootingScreen({super.key});

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
        title: const Text('פתרון בעיות'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('הרשאת פעולה ברקע'),
            subtitle: const Text('נדרש כדי שהאפליקציה תוכל להפעיל התראות'),
            trailing: _isBackgroundPermissionGranted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: _requestBackgroundPermission,
                    child: const Text('אפשר'),
                  ),
          ),
          ListTile(
            title: const Text('ביטול אופטימיזציית סוללה'),
            subtitle: const Text('נדרש לפעולה אמינה של התראות'),
            trailing: _isBatteryOptimizationDisabled
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: _openBatteryOptimizationSettings,
                    child: const Text('הגדר'),
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
        const SnackBar(content: Text('ההרשאה התקבלה בהצלחה')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לאשר את ההרשאה בהגדרות המכשיר')),
      );
    }
  }

  Future<void> _openBatteryOptimizationSettings() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
  
    if (androidInfo.version.sdkInt >= 23) {
      const platform = MethodChannel('com.yddApp.clocki/app_settings');
      try {
        await platform.invokeMethod('openBatteryOptimizationSettings');
        // עדכון מצב ההרשאה לאחר שהמשתמש חוזר מההגדרות
        await Future.delayed(const Duration(seconds: 1));
        await _checkPermissions();
      } on PlatformException catch (e) {
        print("Failed to open battery optimization settings: '${e.message}'.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא ניתן לפתוח את הגדרות אופטימיזציית הסוללה')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אופטימיזציית סוללה אינה רלוונטית לגרסת המכשיר שלך')),
      );
    }
  }
}