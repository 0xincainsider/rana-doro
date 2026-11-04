import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: colors.paper,
    splashFactory: NoSplash.splashFactory,
  );

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.ink,
      brightness: brightness,
    ).copyWith(surface: colors.paper, onSurface: colors.ink),
    textTheme: base.textTheme.apply(
      bodyColor: colors.ink,
      displayColor: colors.ink,
    ),
    extensions: <ThemeExtension<dynamic>>[colors],
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.ink,
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        splashFactory: NoSplash.splashFactory,
        overlayColor: Colors.transparent,
      ),
    ),
  );
}
