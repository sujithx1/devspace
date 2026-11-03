import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/task_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/task.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/widgets.dart';
import '../../../shared/widgets/date_picker_sheet.dart';
import '../task_logic.dart';
import 'task_pickers.dart';

/// Due date, priority, project, tags and repeat for a task. Used by the
/// create sheet and the detail screen; [onChanged] receives the edited task.
class TaskPropertiesSection extends ConsumerWidget {
  const TaskPropertiesSection({super.key, required this.task, required this.onChanged});

  final Task task;
  final ValueChanged<Task> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final brightness = Theme.of(context).brightness;
    Color c(DSPaletteColor p) => p.resolve(brightness);
    final project = task.projectId == null ? null : ref.watch(projectsByIdProvider)[task.projectId];
    final today = ref.watch(todayProvider);

    return DSSection(
      dividerIndent: DSRow.iconIndent,
      children: [
        DSRow(
          leading: DSIconBadge(icon: CupertinoIcons.calendar, color: c(DSPaletteColor.rose)),
          title: 'Due',
          value: task.dueDate == null ? 'None' : dueLabel(task, today),
          showChevron: true,
          onTap: () async {
            final picked = await showDatePickerSheet(context, title: 'Due', date: task.dueDate, time: task.dueTime);
            if (picked != null) onChanged(task.copyWith(dueDate: picked.date, dueTime: picked.time));
          },
        ),
        DSRow(
          leading: DSIconBadge(icon: CupertinoIcons.flag_fill, color: c(DSPaletteColor.amber)),
          title: 'Priority',
          value: task.priority.label,
          showChevron: true,
          onTap: () async {
            final picked = await pickPriority(context, task.priority);
            if (picked != null) onChanged(task.copyWith(priority: picked.value));
          },
        ),
        DSRow(
          leading: DSIconBadge(icon: CupertinoIcons.square_stack_3d_up_fill, color: c(DSPaletteColor.violet)),
          title: 'Project',
          value: project?.name ?? 'None',
          showChevron: true,
          onTap: () async {
            final picked = await pickProject(context, ref, task.projectId);
            if (picked != null) onChanged(task.copyWith(projectId: picked.value));
          },
        ),
        DSRow(
          leading: DSIconBadge(icon: CupertinoIcons.tag_fill, color: c(DSPaletteColor.sky)),
          title: 'Tags',
          value: task.tags.isEmpty ? 'None' : null,
          trailing: task.tags.isEmpty
              ? null
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    task.tags.map((t) => '#$t').join(' '),
                    style: context.type.body.copyWith(color: colors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
          showChevron: true,
          onTap: () async {
            final tags = await editTags(context, task.tags);
            if (tags != null) onChanged(task.copyWith(tags: tags));
          },
        ),
        DSRow(
          leading: DSIconBadge(icon: CupertinoIcons.repeat, color: c(DSPaletteColor.emerald)),
          title: 'Repeat',
          value: task.recurrence?.label ?? 'Never',
          showChevron: true,
          onTap: () async {
            final picked = await pickRecurrence(context, task.recurrence);
            if (picked == null) return;
            // Repeating needs a start date; default to today.
            final needsDate = picked.value != null && task.dueDate == null;
            onChanged(
              task.copyWith(
                recurrence: picked.value,
                dueDate: needsDate ? Dates.toIso(today) : task.dueDate,
              ),
            );
          },
        ),
      ],
    );
  }
}
