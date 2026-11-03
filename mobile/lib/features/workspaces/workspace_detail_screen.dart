import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/workspace_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/models/enums.dart';
import '../../core/models/folder.dart';
import '../../core/models/workspace.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/extensions/date_extensions.dart';
import 'workspace_actions.dart';
import 'workspace_editor_sheet.dart';

class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  const WorkspaceDetailScreen({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<WorkspaceDetailScreen> createState() => _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen> {
  /// Kept so the page doesn't flash empty while popping after a delete.
  Workspace? _lastSeen;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider(widget.workspaceId)) ?? _lastSeen;
    _lastSeen = workspace;
    if (workspace == null) {
      return const DSPage(
        title: 'Workspace',
        largeTitle: false,
        previousPageTitle: 'Workspaces',
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: DSEmptyState(
              icon: CupertinoIcons.trash,
              title: 'Workspace deleted',
              message: 'This workspace no longer exists.',
            ),
          ),
        ],
      );
    }

    final isActive = ref.watch(activeWorkspaceProvider)?.id == workspace.id;
    final stats = ref.watch(workspaceStatsProvider(workspace.id)).value ?? const WorkspaceStats();
    final colors = context.colors;

    return DSPage(
      title: workspace.name,
      largeTitle: false,
      previousPageTitle: 'Workspaces',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => showWorkspaceEditor(context, workspace: workspace),
        child: Text('Edit', style: context.type.body.copyWith(color: colors.accent)),
      ),
      slivers: [
        SliverToBoxAdapter(child: _Header(workspace: workspace, isActive: isActive)),
        SliverToBoxAdapter(
          child: DSSection(
            header: 'Contents',
            dividerIndent: DSRow.iconIndent,
            children: [
              _CountRow(icon: CupertinoIcons.checkmark_circle_fill, color: DSPaletteColor.indigo, label: 'Open Tasks', count: stats.openTasks),
              _CountRow(icon: CupertinoIcons.square_stack_3d_up_fill, color: DSPaletteColor.violet, label: 'Projects', count: stats.projects),
              _CountRow(icon: CupertinoIcons.doc_text_fill, color: DSPaletteColor.amber, label: 'Notes', count: stats.notes),
              _CountRow(icon: CupertinoIcons.book_fill, color: DSPaletteColor.sky, label: 'Docs', count: stats.docs),
              _CountRow(icon: CupertinoIcons.scribble, color: DSPaletteColor.rose, label: 'Drawings', count: stats.drawings),
            ],
          ),
        ),
        SliverToBoxAdapter(child: _FoldersSection(workspaceId: workspace.id)),
        SliverToBoxAdapter(
          child: DSSection(
            footer: 'Deleting a workspace permanently removes everything inside it.',
            children: [
              DSRow(
                title: 'Delete Workspace',
                destructive: true,
                onTap: () async {
                  final deleted = await confirmDeleteWorkspace(context, ref, workspace);
                  if (deleted && context.mounted) Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.workspace, required this.isActive});

  final Workspace workspace;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(DSSpacing.page, DSSpacing.xl, DSSpacing.page, DSSpacing.xl),
      child: Column(
        children: [
          DSEmojiTile(emoji: workspace.icon, size: 84),
          const SizedBox(height: DSSpacing.md),
          Text(workspace.name, style: context.type.title2, textAlign: TextAlign.center),
          const SizedBox(height: DSSpacing.xxs),
          Text(
            'Created ${workspace.createdAt.mediumDate}',
            style: context.type.footnote.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DSSpacing.md),
          AnimatedSwitcher(
            duration: DSMotion.medium,
            child: isActive
                ? Container(
                    key: const ValueKey('active'),
                    padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm, vertical: 6),
                    decoration: BoxDecoration(color: colors.accentSoft, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.checkmark_alt, size: 14, color: colors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Active Workspace',
                          style: context.type.footnote.copyWith(color: colors.accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                : DSButton(
                    key: const ValueKey('switch'),
                    label: 'Switch to This Workspace',
                    variant: DSButtonVariant.tinted,
                    size: DSButtonSize.medium,
                    onPressed: () {
                      Haptics.selection();
                      ref.read(workspaceServiceProvider).switchTo(workspace.id);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.icon, required this.color, required this.label, required this.count});

  final IconData icon;
  final DSPaletteColor color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return DSRow(
      leading: DSIconBadge(icon: icon, color: color.resolve(Theme.of(context).brightness)),
      title: label,
      value: '$count',
    );
  }
}

/// Folders for notes, docs and drawings, one kind at a time.
class _FoldersSection extends ConsumerStatefulWidget {
  const _FoldersSection({required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<_FoldersSection> createState() => _FoldersSectionState();
}

class _FoldersSectionState extends ConsumerState<_FoldersSection> {
  FolderKind _kind = FolderKind.note;

  static const _labels = {FolderKind.note: 'Notes', FolderKind.doc: 'Docs', FolderKind.drawing: 'Drawings'};

  Future<void> _create() async {
    await showDSTextPrompt<Folder>(
      context,
      title: 'New Folder',
      message: 'For ${_labels[_kind]!.toLowerCase()} in this workspace.',
      placeholder: 'Name',
      confirmLabel: 'Create',
      onSubmit: (name) =>
          ref.read(folderRepositoryProvider).create(workspaceId: widget.workspaceId, kind: _kind, name: name),
    );
  }

  Future<void> _rename(Folder folder) async {
    await showDSTextPrompt<Folder>(
      context,
      title: 'Rename Folder',
      initialValue: folder.name,
      placeholder: 'Name',
      confirmLabel: 'Save',
      onSubmit: (name) => ref.read(folderRepositoryProvider).rename(folder.id, name),
    );
  }

  Future<void> _delete(Folder folder) async {
    final confirmed = await showDSConfirm(
      context,
      title: 'Delete “${folder.name}”?',
      message: 'Items inside will move to the top level. Nothing else is deleted.',
      confirmLabel: 'Delete Folder',
    );
    if (!confirmed) return;
    try {
      await ref.read(folderRepositoryProvider).delete(folder.id);
    } catch (e) {
      if (mounted) DSToast.error(context, e);
    }
  }

  Future<void> _showActions(Folder folder) async {
    Haptics.tap();
    final action = await showDSActionSheet<String>(
      context,
      title: folder.name,
      actions: const [
        DSSheetAction(label: 'Rename', value: 'rename'),
        DSSheetAction(label: 'Delete Folder', value: 'delete', destructive: true),
      ],
    );
    if (action == 'rename') await _rename(folder);
    if (action == 'delete') await _delete(folder);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final folders = ref.watch(foldersProvider((workspaceId: widget.workspaceId, kind: _kind))).value ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.sm),
          child: CupertinoSlidingSegmentedControl<FolderKind>(
            groupValue: _kind,
            backgroundColor: colors.fill,
            thumbColor: context.isDark ? colors.fillStrong : colors.surface,
            onValueChanged: (v) {
              if (v == null) return;
              Haptics.selection();
              setState(() => _kind = v);
            },
            children: {
              for (final e in _labels.entries)
                e.key: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(e.value, style: context.type.footnote.copyWith(fontWeight: FontWeight.w600)),
                ),
            },
          ),
        ),
        DSSection(
          header: 'Folders',
          footer: folders.isEmpty ? 'Folders keep ${_labels[_kind]!.toLowerCase()} organised. Long-press a folder to rename or delete it.' : null,
          dividerIndent: DSRow.iconIndent,
          children: [
            for (final f in folders)
              DSRow(
                key: ValueKey(f.id),
                leading: SizedBox(
                  width: DSIconBadge.size,
                  child: Icon(CupertinoIcons.folder_fill, color: colors.accent, size: 24),
                ),
                title: f.name,
                showChevron: false,
                trailing: Icon(CupertinoIcons.ellipsis, color: colors.textTertiary, size: 18),
                onTap: () => _showActions(f),
                onLongPress: () => _showActions(f),
              ),
            DSRow(
              leading: SizedBox(
                width: DSIconBadge.size,
                child: Icon(CupertinoIcons.folder_badge_plus, color: colors.accent, size: 24),
              ),
              title: 'New Folder',
              accent: true,
              onTap: _create,
            ),
          ],
        ),
      ],
    );
  }
}
