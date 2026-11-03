import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'ds_button.dart';

/// Calm, centred message for empty lists and screens.
class DSEmptyState extends StatelessWidget {
  const DSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: DSMotion.slow,
      curve: DSMotion.emphasized,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xxl, vertical: DSSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: colors.fill, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: colors.textSecondary),
            ),
            const SizedBox(height: DSSpacing.lg),
            Text(title, style: context.type.title3, textAlign: TextAlign.center),
            const SizedBox(height: DSSpacing.xs),
            Text(
              message,
              style: context.type.subheadline.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DSSpacing.xl),
              DSButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: DSButtonVariant.tinted,
                size: DSButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
