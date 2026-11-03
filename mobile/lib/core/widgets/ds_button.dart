import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'ds_pressable.dart';

enum DSButtonVariant { filled, tinted, plain, destructive }

enum DSButtonSize { large, medium, small }

class DSButton extends StatelessWidget {
  const DSButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = DSButtonVariant.filled,
    this.size = DSButtonSize.large,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DSButtonVariant variant;
  final DSButtonSize size;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final (Color bg, Color fg) = switch (variant) {
      DSButtonVariant.filled => (colors.accent, colors.onAccent),
      DSButtonVariant.tinted => (colors.accentSoft, colors.accent),
      DSButtonVariant.plain => (Colors.transparent, colors.accent),
      DSButtonVariant.destructive => (colors.danger.withValues(alpha: 0.12), colors.danger),
    };
    final (EdgeInsets padding, double radius, TextStyle text, double iconSize) = switch (size) {
      DSButtonSize.large => (
        const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: 15),
        14.0,
        type.headline,
        19.0,
      ),
      DSButtonSize.medium => (
        const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: 10),
        11.0,
        type.subheadline.copyWith(fontWeight: FontWeight.w600),
        17.0,
      ),
      DSButtonSize.small => (
        const EdgeInsets.symmetric(horizontal: DSSpacing.sm, vertical: 6),
        999.0,
        type.footnote.copyWith(fontWeight: FontWeight.w600),
        14.0,
      ),
    };
    final enabled = onPressed != null && !loading;

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          CupertinoActivityIndicator(color: fg, radius: iconSize / 2.2)
        else ...[
          if (icon != null) ...[Icon(icon, size: iconSize, color: fg), const SizedBox(width: 6)],
          Flexible(
            child: Text(label, style: text.copyWith(color: fg), overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ],
      ],
    );

    return DSPressable(
      onPressed: enabled ? onPressed : null,
      haptic: variant != DSButtonVariant.plain,
      semanticLabel: label,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.4 : 1,
        duration: DSMotion.fast,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
          child: ExcludeSemantics(child: child),
        ),
      ),
    );
  }
}
