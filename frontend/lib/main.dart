import 'package:flutter/material.dart';
import '../screens/home/homepage.dart';
import '../l10n/app_localization.dart';
import '../l10n/l10n.dart';
import '../models/locale.dart';
import 'l10n/app_localization.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      //home: const HomePage(),
    );
  }
}
