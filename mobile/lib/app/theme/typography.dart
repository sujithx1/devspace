import 'package:flutter/material.dart';

/// Type scale based on the iOS text styles, rendered in SF Pro with Apple's
/// tracking values. Sizes are in points and scale with Dynamic Type through
/// the platform text scaler, so never wrap text in fixed-height boxes.
@immutable
class DSTypography extends ThemeExtension<DSTypography> {
  const DSTypography._({
    required this.largeTitle,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.headline,
    required this.body,
    required this.callout,
    required this.subheadline,
    required this.footnote,
    required this.caption,
    required this.caption2,
    required this.mono,
  });

  factory DSTypography.withColor(Color color) {
    TextStyle style(double size, FontWeight weight, double tracking, double height) => TextStyle(
      fontFamily: size >= 20 ? 'CupertinoSystemDisplay' : 'CupertinoSystemText',
      fontSize: size,
      fontWeight: weight,
      letterSpacing: tracking,
      height: height,
      color: color,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return DSTypography._(
      largeTitle: style(34, FontWeight.w700, 0.37, 1.2),
      title1: style(28, FontWeight.w700, 0.36, 1.21),
      title2: style(22, FontWeight.w700, 0.35, 1.27),
      title3: style(20, FontWeight.w600, 0.38, 1.25),
      headline: style(17, FontWeight.w600, -0.43, 1.29),
      body: style(17, FontWeight.w400, -0.43, 1.29),
      callout: style(16, FontWeight.w400, -0.31, 1.31),
      subheadline: style(15, FontWeight.w400, -0.23, 1.33),
      footnote: style(13, FontWeight.w400, -0.08, 1.38),
      caption: style(12, FontWeight.w400, 0, 1.33),
      caption2: style(11, FontWeight.w500, 0.07, 1.18),
      mono: TextStyle(fontFamily: 'Menlo', fontSize: 14, height: 1.45, color: color),
    );
  }

  final TextStyle largeTitle;
  final TextStyle title1;
  final TextStyle title2;
  final TextStyle title3;
  final TextStyle headline;
  final TextStyle body;
  final TextStyle callout;
  final TextStyle subheadline;
  final TextStyle footnote;
  final TextStyle caption;
  final TextStyle caption2;
  final TextStyle mono;

  @override
  DSTypography copyWith() => this;

  @override
  DSTypography lerp(DSTypography? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return DSTypography._(
      largeTitle: l(largeTitle, other.largeTitle),
      title1: l(title1, other.title1),
      title2: l(title2, other.title2),
      title3: l(title3, other.title3),
      headline: l(headline, other.headline),
      body: l(body, other.body),
      callout: l(callout, other.callout),
      subheadline: l(subheadline, other.subheadline),
      footnote: l(footnote, other.footnote),
      caption: l(caption, other.caption),
      caption2: l(caption2, other.caption2),
      mono: l(mono, other.mono),
    );
  }
}
