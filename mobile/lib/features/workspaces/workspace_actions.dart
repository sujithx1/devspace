import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../core/models/workspace.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import 'workspace_editor_sheet.dart';

enum _WorkspaceAction { edit, delete }

/// Long-press menu for a workspace.
Future<void> showWorkspaceActions(BuildContext context, WidgetRef ref, Workspace workspace) async {
  Haptics.tap();
  final action = await showDSActionSheet<_WorkspaceAction>(
    context,
    title: workspace.name,
    actions: const [
      DSSheetAction(label: 'Edit Name & Icon', value: _WorkspaceAction.edit),
      DSSheetAction(label: 'Delete Workspace', value: _WorkspaceAction.delete, destructive: true),
    ],
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case _WorkspaceAction.edit:
      await showWorkspaceEditor(context, workspace: workspace);
    case _WorkspaceAction.delete:
      await confirmDeleteWorkspace(context, ref, workspace);
  }
}

/// Asks for confirmation, then deletes [workspace] and everything in it.
/// Returns true when it was deleted.
Future<bool> confirmDeleteWorkspace(BuildContext context, WidgetRef ref, Workspace workspace) async {
  final confirmed = await showDSConfirm(
    context,
    title: 'Delete “${workspace.name}”?',
    message: 'All tasks, projects, notes, docs, drawings and folders in this workspace will be permanently deleted.',
    confirmLabel: 'Delete',
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await ref.read(workspaceServiceProvider).delete(workspace.id);
    if (context.mounted) DSToast.show(context, 'Deleted “${workspace.name}”', tone: DSToastTone.success);
    return true;
  } catch (e) {
    if (context.mounted) DSToast.error(context, e);
    return false;
  }
}
