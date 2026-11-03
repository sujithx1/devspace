import 'package:flutter/cupertino.dart';

import '../../app/theme/app_theme.dart';

/// The DevSpace app mark: a soft accent tile with a code glyph.
class DevSpaceMark extends StatelessWidget {
  const DevSpaceMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(color: colors.accent.withValues(alpha: 0.35), blurRadius: size * 0.4, offset: Offset(0, size * 0.12)),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(CupertinoIcons.chevron_left_slash_chevron_right, color: colors.onAccent, size: size * 0.46),
    );
  }
}
