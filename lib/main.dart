import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:chat1/SideBar/leftBar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/ui_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode') ?? true;
  HttpOverrides.global = MyHttpOverrides();
  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(1200, 700);
    win.size = const Size(1200, 700);
    appWindow.title = "ana ga3an";
    win.show();
  });

  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData(
        tabBarTheme: const TabBarTheme(
          dividerColor: Colors.transparent, // ✅ Fully remove bottom line
        ),
        scaffoldBackgroundColor: UIColors.backgroundColor,
        brightness: Brightness.dark,
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Color(0xFF202020),
          selectedIconTheme: IconThemeData(size: 28, color: Color(0xFF64FFDA)),
          unselectedIconTheme:
              IconThemeData(size: 24, color: Colors.grey.shade600),
          selectedLabelTextStyle: TextStyle(
            fontSize: 14,
            color: Color(0xFF64FFDA),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelTextStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            letterSpacing: 0.3,
          ),
          elevation: 4,
          useIndicator: true,
          indicatorColor: Color(0xFF64FFDA).withOpacity(0.1),
        ),
      ),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        tabBarTheme: const TabBarTheme(
          dividerColor: Colors.transparent,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Color(0xFF202020),
          selectedIconTheme: IconThemeData(size: 28, color: Color(0xFF64FFDA)),
          unselectedIconTheme:
              IconThemeData(size: 24, color: Colors.grey.shade600),
          selectedLabelTextStyle: TextStyle(
            fontSize: 14,
            color: Color(0xFF64FFDA),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelTextStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            letterSpacing: 0.3,
          ),
          elevation: 4,
          useIndicator: true,
          indicatorColor: Color(0xFF64FFDA).withOpacity(0.1),
        ),
      ),
      home: Leftbar(),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
