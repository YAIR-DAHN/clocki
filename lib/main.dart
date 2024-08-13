import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home.dart';

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
        ColorScheme lightColorScheme = lightDynamic ?? ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        );

        ColorScheme darkColorScheme = darkDynamic ?? ColorScheme.fromSeed(
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
              bodyColor: lightColorScheme.onBackground,
              displayColor: lightColorScheme.onBackground,
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              bodyColor: darkColorScheme.onBackground,
              displayColor: darkColorScheme.onBackground,
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          home: HomeScreen(),
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