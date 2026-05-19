import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MorseOSApp());
}

class MorseOSApp extends StatelessWidget {
  const MorseOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'MorseOS',
      debugShowCheckedModeBanner: false,
      theme:                      AppTheme.dark,
      home:                       const AppShell(),
    );
  }
}
