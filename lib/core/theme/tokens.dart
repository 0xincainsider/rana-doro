import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paper,
    required this.ink,
    required this.inkMuted,
    required this.grayDecorative,
    required this.shadow,
  });

  final Color paper;
  final Color ink;
  final Color inkMuted;
  final Color grayDecorative;
  final Color shadow;

  static const AppColors light = AppColors(
    paper: Color(0xFFF6F1E7),
    ink: Color(0xFF121212),
    inkMuted: Color(0xFF5F5F5F),
    grayDecorative: Color(0xFF8A8A8A),
    shadow: Color(0x0D000000),
  );

  static const AppColors dark = AppColors(
    paper: Color(0xFF121212),
    ink: Color(0xFFF6F1E7),
    inkMuted: Color(0xFFC9C3B8),
    grayDecorative: Color(0xFF8A8A8A),
    shadow: Color(0x26F6F1E7),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? AppColors.light;
  }

  @override
  AppColors copyWith({
    Color? paper,
    Color? ink,
    Color? inkMuted,
    Color? grayDecorative,
    Color? shadow,
  }) {
    return AppColors(
      paper: paper ?? this.paper,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      grayDecorative: grayDecorative ?? this.grayDecorative,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppColors(
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      grayDecorative: Color.lerp(grayDecorative, other.grayDecorative, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppColors &&
        other.paper == paper &&
        other.ink == ink &&
        other.inkMuted == inkMuted &&
        other.grayDecorative == grayDecorative &&
        other.shadow == shadow;
  }

  @override
  int get hashCode => Object.hash(paper, ink, inkMuted, grayDecorative, shadow);
}

const TextStyle _timeBase = TextStyle(
  fontFamily: 'Inter',
  fontVariations: <FontVariation>[
    FontVariation('wght', 500),
    FontVariation('opsz', 72),
  ],
  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  letterSpacing: -2,
  height: 1,
);

TextStyle timeStyle(double size, Color color) {
  return _timeBase.copyWith(fontSize: size, color: color);
}

TextStyle caveatStyle(
  double size, {
  Color? color,
  double weight = 600,
  double height = 1,
}) {
  return TextStyle(
    fontFamily: 'Caveat',
    fontSize: size,
    fontVariations: <FontVariation>[FontVariation('wght', weight)],
    color: color,
    height: height,
  );
}

const double kMinTouchTarget = 48;
