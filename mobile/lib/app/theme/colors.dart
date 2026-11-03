import 'package:flutter/material.dart';

/// Semantic colour palette. Widgets read colours from here (via `context.colors`)
/// and never hard-code hex values.
@immutable
class DSColors extends ThemeExtension<DSColors> {
  const DSColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.fill,
    required this.fillStrong,
    required this.separator,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.shadow,
  });

  /// Page background.
  final Color background;

  /// Grouped sections and rows that sit on [background].
  final Color surface;

  /// Sheets, popovers, and anything layered above [surface].
  final Color surfaceElevated;

  /// Input fields and pressed states.
  final Color fill;
  final Color fillStrong;

  final Color separator;
  final Color border;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color accent;

  /// Tinted backgrounds for accent-coloured content.
  final Color accentSoft;
  final Color onAccent;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  final Color shadow;

  static const light = DSColors(
    background: Color(0xFFF6F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    fill: Color(0x0F1C1C28),
    fillStrong: Color(0x1A1C1C28),
    separator: Color(0x1F1C1C28),
    border: Color(0x141C1C28),
    textPrimary: Color(0xFF16161D),
    textSecondary: Color(0xFF6B6B76),
    textTertiary: Color(0xFFA2A2AC),
    accent: Color(0xFF5B57E0),
    accentSoft: Color(0x1A5B57E0),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF2FA866),
    warning: Color(0xFFE59A1A),
    danger: Color(0xFFE5484D),
    info: Color(0xFF2E8AE6),
    shadow: Color(0x141C1C28),
  );

  static const dark = DSColors(
    background: Color(0xFF0B0B0E),
    surface: Color(0xFF17171B),
    surfaceElevated: Color(0xFF1E1E23),
    fill: Color(0x14FFFFFF),
    fillStrong: Color(0x24FFFFFF),
    separator: Color(0x1FFFFFFF),
    border: Color(0x14FFFFFF),
    textPrimary: Color(0xFFF2F2F5),
    textSecondary: Color(0xFF9E9EA8),
    textTertiary: Color(0xFF62626C),
    accent: Color(0xFF7C78FF),
    accentSoft: Color(0x297C78FF),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF3CC47C),
    warning: Color(0xFFF0AE3A),
    danger: Color(0xFFFF6369),
    info: Color(0xFF4FA3F7),
    shadow: Color(0x66000000),
  );

  @override
  DSColors copyWith({Color? accent, Color? accentSoft}) => DSColors(
    background: background,
    surface: surface,
    surfaceElevated: surfaceElevated,
    fill: fill,
    fillStrong: fillStrong,
    separator: separator,
    border: border,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textTertiary: textTertiary,
    accent: accent ?? this.accent,
    accentSoft: accentSoft ?? this.accentSoft,
    onAccent: onAccent,
    success: success,
    warning: warning,
    danger: danger,
    info: info,
    shadow: shadow,
  );

  @override
  DSColors lerp(DSColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DSColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      fill: l(fill, other.fill),
      fillStrong: l(fillStrong, other.fillStrong),
      separator: l(separator, other.separator),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      onAccent: l(onAccent, other.onAccent),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      info: l(info, other.info),
      shadow: l(shadow, other.shadow),
    );
  }
}

/// Palette for user-chosen colours (projects, folders). Names match the web app.
enum DSPaletteColor {
  indigo(Color(0xFF5B57E0), Color(0xFF7C78FF)),
  emerald(Color(0xFF1F9D6B), Color(0xFF3CC48C)),
  amber(Color(0xFFD98B0B), Color(0xFFF0AE3A)),
  rose(Color(0xFFE0456B), Color(0xFFFF6B8E)),
  sky(Color(0xFF1E8FD8), Color(0xFF4FB3F7)),
  violet(Color(0xFF9A4DE0), Color(0xFFB57CFF)),
  zinc(Color(0xFF71717A), Color(0xFFA1A1AA));

  const DSPaletteColor(this.light, this.dark);
  final Color light;
  final Color dark;

  Color resolve(Brightness brightness) => brightness == Brightness.dark ? dark : light;
}
