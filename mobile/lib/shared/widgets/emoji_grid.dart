import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/services/haptics.dart';
import '../constants/workspace_icons.dart';

/// Grid of selectable emoji with an animated selection ring.
class EmojiGrid extends StatelessWidget {
  const EmojiGrid({super.key, required this.selected, required this.onSelected, this.options = workspaceIcons});

  final String selected;
  final ValueChanged<String> onSelected;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 8;
        const gap = 6.0;
        final size = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final emoji in options)
              Semantics(
                button: true,
                selected: emoji == selected,
                label: 'Icon $emoji',
                child: GestureDetector(
                  onTap: () {
                    Haptics.selection();
                    onSelected(emoji);
                  },
                  child: AnimatedContainer(
                    duration: DSMotion.medium,
                    curve: DSMotion.standard,
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: emoji == selected ? colors.accentSoft : colors.fill,
                      borderRadius: BorderRadius.circular(DSRadius.sm + 2),
                      border: Border.all(color: emoji == selected ? colors.accent : Colors.transparent, width: 1.5),
                    ),
                    child: Text(emoji, textScaler: TextScaler.noScaling, style: TextStyle(fontSize: size * 0.5)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
