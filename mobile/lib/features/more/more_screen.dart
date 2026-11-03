import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/workspace_providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/widgets.dart';
import '../workspaces/workspace_summary.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(activeWorkspaceProvider);
    final stats = workspace == null ? null : ref.watch(workspaceStatsProvider(workspace.id)).value;
    final brightness = Theme.of(context).brightness;
    Color c(DSPaletteColor p) => p.resolve(brightness);

    return DSPage(
      title: 'More',
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.xs)),
        if (workspace != null)
          SliverToBoxAdapter(
            child: DSSection(
              children: [
                DSRow(
                  leading: DSEmojiTile(emoji: workspace.icon, size: 44),
                  title: workspace.name,
                  subtitle: workspaceSummary(stats),
                  showChevron: true,
                  onTap: () => context.push(Routes.workspace(workspace.id)),
                ),
              ],
            ),
          ),
        SliverToBoxAdapter(
          child: DSSection(
            header: 'Library',
            dividerIndent: DSRow.iconIndent,
            children: [
              DSRow(
                leading: DSIconBadge(icon: CupertinoIcons.book_fill, color: c(DSPaletteColor.sky)),
                title: 'Documentation',
                value: 'Soon',
                enabled: false,
              ),
              DSRow(
                leading: DSIconBadge(icon: CupertinoIcons.scribble, color: c(DSPaletteColor.rose)),
                title: 'Drawings',
                value: 'Soon',
                enabled: false,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: DSSection(
            header: 'Organize',
            dividerIndent: DSRow.iconIndent,
            children: [
              DSRow(
                leading: DSIconBadge(icon: CupertinoIcons.square_grid_2x2_fill, color: c(DSPaletteColor.indigo)),
                title: 'Workspaces',
                showChevron: true,
                onTap: () => context.push(Routes.workspaces),
              ),
              DSRow(
                leading: DSIconBadge(icon: CupertinoIcons.search, color: c(DSPaletteColor.emerald)),
                title: 'Search',
                value: 'Soon',
                enabled: false,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: DSSection(
            dividerIndent: DSRow.iconIndent,
            children: [
              DSRow(
                leading: DSIconBadge(icon: CupertinoIcons.gear_alt_fill, color: c(DSPaletteColor.zinc)),
                title: 'Settings',
                showChevron: true,
                onTap: () => context.push(Routes.settings),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
