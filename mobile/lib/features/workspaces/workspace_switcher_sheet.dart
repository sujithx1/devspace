import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/workspace_providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import 'workspace_editor_sheet.dart';
import 'workspace_summary.dart';

/// Quick workspace switcher presented from Home.
Future<void> showWorkspaceSwitcher(BuildContext context) {
  return showDSBottomSheet<void>(context, builder: (_) => const _WorkspaceSwitcher());
}

class _WorkspaceSwitcher extends ConsumerWidget {
  const _WorkspaceSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(workspacesProvider).value ?? const [];
    final active = ref.watch(activeWorkspaceProvider);
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DSSpacing.page + DSSpacing.xxs, 0, DSSpacing.page, DSSpacing.md),
              child: Text('Workspaces', style: context.type.title3),
            ),
            DSSection(
              dividerIndent: DSRow.iconIndent,
              children: [
                for (final w in workspaces)
                  DSRow(
                    leading: DSEmojiTile(emoji: w.icon),
                    title: w.name,
                    subtitle: workspaceSummary(ref.watch(workspaceStatsProvider(w.id)).value),
                    trailing: w.id == active?.id
                        ? Icon(CupertinoIcons.checkmark_alt, color: colors.accent, size: 22)
                        : null,
                    onTap: () async {
                      Haptics.selection();
                      await ref.read(workspaceServiceProvider).switchTo(w.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
            DSSection(
              dividerIndent: DSRow.iconIndent,
              children: [
                DSRow(
                  leading: Icon(CupertinoIcons.plus_circle_fill, color: colors.accent, size: DSIconBadge.size),
                  title: 'New Workspace',
                  accent: true,
                  onTap: () {
                    Navigator.pop(context);
                    showWorkspaceEditor(rootNavigatorKey.currentContext!);
                  },
                ),
                DSRow(
                  leading: Icon(CupertinoIcons.slider_horizontal_3, color: colors.textSecondary, size: 26),
                  title: 'Manage Workspaces',
                  showChevron: true,
                  onTap: () {
                    Navigator.pop(context);
                    GoRouter.of(rootNavigatorKey.currentContext!).go(Routes.workspaces);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
