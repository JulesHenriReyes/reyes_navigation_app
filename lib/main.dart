import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_screen.dart';

void main() {
  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  final int? initialTab;
  const StudentApp({super.key, this.initialTab});

  @override
  Widget build(BuildContext context) {
    Widget initialScreen = const LoginScreen();
    final tabQuery = Uri.base.queryParameters['tab'];
    final tabIndex = initialTab ?? (tabQuery != null ? int.tryParse(tabQuery) : null);

    if (tabIndex != null && tabIndex >= 0 && tabIndex <= 3) {
      initialScreen = MainScreen(initialIndex: tabIndex);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Navigation App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}
