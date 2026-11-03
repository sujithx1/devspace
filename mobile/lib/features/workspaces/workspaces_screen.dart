import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/workspace_providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/workspace.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import 'workspace_actions.dart';
import 'workspace_editor_sheet.dart';
import 'workspace_summary.dart';

class WorkspacesScreen extends ConsumerWidget {
  const WorkspacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(workspacesProvider);
    final active = ref.watch(activeWorkspaceProvider);

    return DSPage(
      title: 'Workspaces',
      previousPageTitle: 'More',
      trailing: DSNavIconButton(
        icon: CupertinoIcons.plus,
        semanticLabel: 'New Workspace',
        onPressed: () => showWorkspaceEditor(context),
      ),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.xs)),
        switch (workspaces) {
          AsyncData(:final value) => SliverToBoxAdapter(
            child: DSSection(
              dividerIndent: DSRow.iconIndent,
              footer: 'Tap a workspace to switch to it. Everything you create belongs to the active workspace.',
              children: [for (final w in value) _WorkspaceRow(workspace: w, isActive: w.id == active?.id)],
            ),
          ),
          AsyncError(:final error) => SliverFillRemaining(
            hasScrollBody: false,
            child: DSEmptyState(
              icon: CupertinoIcons.exclamationmark_triangle,
              title: 'Couldn’t load workspaces',
              message: '$error',
            ),
          ),
          _ => const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator())),
        },
      ],
    );
  }
}

class _WorkspaceRow extends ConsumerWidget {
  const _WorkspaceRow({required this.workspace, required this.isActive});

  final Workspace workspace;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final stats = ref.watch(workspaceStatsProvider(workspace.id)).value;
    return DSRow(
      leading: DSEmojiTile(emoji: workspace.icon, size: 36),
      title: workspace.name,
      subtitle: isActive ? 'Active · ${workspaceSummary(stats)}' : workspaceSummary(stats),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: isActive ? 1 : 0,
            duration: DSMotion.medium,
            child: Icon(CupertinoIcons.checkmark_alt, color: colors.accent, size: 22),
          ),
          CupertinoButton(
            padding: const EdgeInsets.only(left: DSSpacing.xs),
            minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
            onPressed: () => context.push(Routes.workspace(workspace.id)),
            child: Semantics(
              label: 'Workspace details',
              child: Icon(CupertinoIcons.info_circle, color: colors.accent, size: 22),
            ),
          ),
        ],
      ),
      onTap: () {
        if (isActive) return;
        Haptics.selection();
        ref.read(workspaceServiceProvider).switchTo(workspace.id);
      },
      onLongPress: () => showWorkspaceActions(context, ref, workspace),
    );
  }
}
