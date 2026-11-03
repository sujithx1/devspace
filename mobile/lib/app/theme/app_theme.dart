import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

export 'colors.dart';
export 'tokens.dart';
export 'typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, DSColors.light);
  static ThemeData dark() => _build(Brightness.dark, DSColors.dark);

  static ThemeData _build(Brightness brightness, DSColors c) {
    final type = DSTypography.withColor(c.textPrimary);
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
    ).copyWith(primary: c.accent, onPrimary: c.onAccent, surface: c.surface, error: c.danger);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      platform: TargetPlatform.iOS,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.separator,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.25),
        selectionHandleColor: c.accent,
      ),
      textTheme: TextTheme(
        displayLarge: type.largeTitle,
        headlineLarge: type.title1,
        headlineMedium: type.title2,
        headlineSmall: type.title3,
        titleLarge: type.title3,
        titleMedium: type.headline,
        titleSmall: type.subheadline,
        bodyLarge: type.body,
        bodyMedium: type.callout,
        bodySmall: type.footnote,
        labelLarge: type.headline,
        labelMedium: type.footnote,
        labelSmall: type.caption2,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
      ),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: brightness,
        primaryColor: c.accent,
        primaryContrastingColor: c.onAccent,
        scaffoldBackgroundColor: c.background,
        barBackgroundColor: c.background.withValues(alpha: 0.82),
        textTheme: CupertinoTextThemeData(
          primaryColor: c.accent,
          textStyle: type.body,
          navTitleTextStyle: type.headline,
          navLargeTitleTextStyle: type.largeTitle,
          actionTextStyle: type.body.copyWith(color: c.accent),
          navActionTextStyle: type.body.copyWith(color: c.accent),
        ),
      ),
      extensions: [c, type],
    );
  }
}

extension DSThemeContext on BuildContext {
  DSColors get colors => Theme.of(this).extension<DSColors>()!;
  DSTypography get type => Theme.of(this).extension<DSTypography>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
