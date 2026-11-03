import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DSTabItem {
  const DSTabItem({required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Translucent bottom tab bar with a blurred backdrop and hairline top edge.
class DSTabBar extends StatelessWidget {
  const DSTabBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  static const double height = 50;

  final List<DSTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: 0.82),
            border: Border(top: BorderSide(color: colors.separator, width: 0.5)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
            child: SizedBox(
              height: height,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _TabButton(item: items[i], selected: i == currentIndex, onTap: () => onTap(i)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.item, required this.selected, required this.onTap});

  final DSTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.accent : colors.textTertiary;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(selected),
              tween: Tween(begin: selected ? 0.82 : 1, end: 1),
              duration: DSMotion.slow,
              curve: Curves.elasticOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Icon(selected ? item.activeIcon : item.icon, size: 24, color: color),
            ),
            const SizedBox(height: 3),
            // Tab labels stay compact at large text sizes, like UIKit's tab bar.
            Text(
              item.label,
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
              style: TextStyle(
                fontFamily: 'CupertinoSystemText',
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
