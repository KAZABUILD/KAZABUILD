import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'theme for app',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // auto switch (light/dark)
      home: Scaffold(
        appBar: AppBar(title: Text("Theme Example")),
        body: Center(
          child: ElevatedButton(
            onPressed: () {},
            child: Text("Themed Button"),
          ),
        ),
      ),
    );
  }
}
