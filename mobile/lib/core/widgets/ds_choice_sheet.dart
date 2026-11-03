import 'package:flutter/cupertino.dart';

import '../../app/theme/app_theme.dart';
import '../services/haptics.dart';
import 'ds_section.dart';
import 'ds_sheet.dart';

class DSChoice<T> {
  const DSChoice({required this.value, required this.label, this.subtitle, this.leading});

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
}

/// Bottom sheet listing [choices] with a checkmark on [selected]. Resolves to
/// the picked choice, or null when dismissed. Wrap the value in a record when
/// "none" must be distinguishable from dismissal.
Future<DSChoice<T>?> showDSChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<DSChoice<T>> choices,
  T? selected,
  String? footer,
}) {
  return showDSBottomSheet<DSChoice<T>>(
    context,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DSSpacing.page + DSSpacing.xxs, 0, DSSpacing.page, DSSpacing.md),
              child: Text(title, style: context.type.title3),
            ),
            DSSection(
              footer: footer,
              dividerIndent: choices.any((c) => c.leading != null) ? DSRow.iconIndent : DSSpacing.md,
              children: [
                for (final c in choices)
                  DSRow(
                    leading: c.leading == null ? null : SizedBox(width: DSIconBadge.size, child: Center(child: c.leading)),
                    title: c.label,
                    subtitle: c.subtitle,
                    trailing: c.value == selected
                        ? Icon(CupertinoIcons.checkmark_alt, color: context.colors.accent, size: 22)
                        : null,
                    onTap: () {
                      Haptics.selection();
                      Navigator.pop(context, c);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
