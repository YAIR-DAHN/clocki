import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:clocki/screens/home.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Alarm.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightColorScheme = lightDynamic ?? ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        );

        final darkColorScheme = darkDynamic ?? ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        );

        return MaterialApp(
          title: 'קלוקי - שעון המעורר שלי',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            textTheme: TextTheme(
              displayLarge: GoogleFonts.heebo(fontSize: 32, fontWeight: FontWeight.bold),
              displayMedium: GoogleFonts.heebo(fontSize: 28, fontWeight: FontWeight.w600),
              bodyLarge: GoogleFonts.heebo(fontSize: 16),
              bodyMedium: GoogleFonts.heebo(fontSize: 14),
            ).apply(
              bodyColor: lightColorScheme.onSurface,
              displayColor: lightColorScheme.onSurface,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: lightColorScheme.primaryContainer,
              foregroundColor: lightColorScheme.onPrimaryContainer,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: lightColorScheme.onPrimary,
                backgroundColor: lightColorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: lightColorScheme.primaryContainer,
              foregroundColor: lightColorScheme.onPrimaryContainer,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            textTheme: TextTheme(
              displayLarge: GoogleFonts.heebo(fontSize: 32, fontWeight: FontWeight.bold),
              displayMedium: GoogleFonts.heebo(fontSize: 28, fontWeight: FontWeight.w600),
              bodyLarge: GoogleFonts.heebo(fontSize: 16),
              bodyMedium: GoogleFonts.heebo(fontSize: 14),
            ).apply(
              bodyColor: darkColorScheme.onSurface,
              displayColor: darkColorScheme.onSurface,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: darkColorScheme.primaryContainer,
              foregroundColor: darkColorScheme.onPrimaryContainer,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: darkColorScheme.onPrimary,
                backgroundColor: darkColorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: darkColorScheme.primaryContainer,
              foregroundColor: darkColorScheme.onPrimaryContainer,
            ),
          ),
          home: const UpdateWrapper(child: HomeScreen()),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('he', 'IL'),
          ],
          locale: const Locale('he', 'IL'),
        );
      },
    );
  }
}

class UpdateWrapper extends StatefulWidget {
  final Widget child;

  const UpdateWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _UpdateWrapperState createState() => _UpdateWrapperState();
}

class _UpdateWrapperState extends State<UpdateWrapper> {
  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    PackageInfo packageInfo = await PackageManager.getPackageInfo();

    if (Platform.isAndroid) {
      InAppUpdateManager manager = InAppUpdateManager();
      AppUpdateInfo? appUpdateInfo = await manager.checkForUpdate();
      if (appUpdateInfo != null &&
          appUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (appUpdateInfo.immediateAllowed) {
          await manager.startAnUpdate(type: AppUpdateType.immediate);
        } else if (appUpdateInfo.flexibleAllowed) {
          await manager.startAnUpdate(type: AppUpdateType.flexible);
        }
      }
    } else if (Platform.isIOS) {
      VersionInfo? versionInfo = await UpgradeVersion.getiOSStoreVersion(
        packageInfo: packageInfo,
        regionCode: 'IL', // קוד המדינה של ישראל
      );

      if (versionInfo != null && versionInfo.canUpdate) {
        _showUpdateDialog(versionInfo);
      }
    }
  }

  void _showUpdateDialog(VersionInfo versionInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('עדכון זמין'),
          content: Text('גרסה חדשה (${versionInfo.storeVersion}) זמינה. האם ברצונך לעדכן?'),
          actions: <Widget>[
            TextButton(
              child: const Text('לא עכשיו'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('עדכן'),
              onPressed: () {
                Navigator.of(context).pop();
                _launchAppStore(versionInfo.appStoreLink);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchAppStore(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('לא ניתן לפתוח את ה-URL: $url');
      // כאן תוכל להוסיף הודעת שגיאה למשתמש אם רצונך
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}