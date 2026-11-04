import 'package:flutter/material.dart';

import 'core/brand.dart';
import 'core/theme/app_theme.dart';
import 'features/timer/application/timer_controller.dart';
import 'features/timer/presentation/timer_screen.dart';

class RanadoroApp extends StatelessWidget {
  const RanadoroApp({super.key, required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: TimerScreen(controller: controller),
    );
  }
}
