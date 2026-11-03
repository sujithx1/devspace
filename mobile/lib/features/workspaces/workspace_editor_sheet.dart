import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/workspace.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/widgets/emoji_grid.dart';

/// Creates a workspace (and switches to it), or edits [workspace]'s name and icon.
Future<Workspace?> showWorkspaceEditor(BuildContext context, {Workspace? workspace}) {
  return showDSSheet<Workspace>(
    context,
    builder: (context, controller) => _WorkspaceEditor(workspace: workspace, scrollController: controller),
  );
}

class _WorkspaceEditor extends ConsumerStatefulWidget {
  const _WorkspaceEditor({required this.workspace, required this.scrollController});

  final Workspace? workspace;
  final ScrollController scrollController;

  @override
  ConsumerState<_WorkspaceEditor> createState() => _WorkspaceEditorState();
}

class _WorkspaceEditorState extends ConsumerState<_WorkspaceEditor> {
  late final _name = TextEditingController(text: widget.workspace?.name ?? '');
  final _nameFocus = FocusNode();
  late String _icon = widget.workspace?.icon ?? '💻';
  String? _error;
  bool _busy = false;

  bool get _isNew => widget.workspace == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Focus once the sheet has finished sliding up; focusing mid-transition
    // gets dropped and the keyboard would flash closed.
    final animation = ModalRoute.of(context)?.animation;
    if (_isNew && animation != null && !_focusScheduled) {
      _focusScheduled = true;
      void focusWhenDone(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          animation.removeStatusListener(focusWhenDone);
          if (mounted) _nameFocus.requestFocus();
        }
      }

      if (animation.isCompleted) {
        _nameFocus.requestFocus();
      } else {
        animation.addStatusListener(focusWhenDone);
      }
    }
  }

  bool _focusScheduled = false;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = ref.read(workspaceServiceProvider);
    try {
      final saved = _isNew
          ? await service.create(name: _name.text, icon: _icon)
          : await service.update(widget.workspace!.id, name: _name.text, icon: _icon);
      Haptics.success();
      if (mounted) Navigator.of(context).pop(saved);
    } on ValidationException catch (e) {
      Haptics.warning();
      setState(() => _error = e.fieldErrors['name'] ?? e.message);
    } catch (e) {
      if (mounted) DSToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ValueListenableBuilder(
      valueListenable: _name,
      builder: (context, value, _) => DSSheetScaffold(
        title: _isNew ? 'New Workspace' : 'Edit Workspace',
        doneLabel: _isNew ? 'Create' : 'Save',
        scrollController: widget.scrollController,
        busy: _busy,
        onDone: value.text.trim().isEmpty ? null : _save,
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: DSMotion.medium,
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: DSEmojiTile(key: ValueKey(_icon), emoji: _icon, size: 80),
            ),
          ),
          const SizedBox(height: DSSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
            child: DSTextField(
              controller: _name,
              focusNode: _nameFocus,
              label: 'Name',
              placeholder: 'Workspace name',
              error: _error,
              maxLength: 60,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) _save();
              },
            ),
          ),
          const SizedBox(height: DSSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: DSSpacing.xxs, bottom: DSSpacing.xs),
                  child: Text(
                    'Icon',
                    style: context.type.footnote.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
                EmojiGrid(selected: _icon, onSelected: (v) => setState(() => _icon = v)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
