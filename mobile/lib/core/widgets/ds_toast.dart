import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../errors/app_exception.dart';
import '../services/haptics.dart';

enum DSToastTone { neutral, success, error }

/// Small floating banner that drops in from the top and dismisses itself.
abstract final class DSToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    DSToastTone tone = DSToastTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    if (tone == DSToastTone.error) Haptics.warning();
  }

  /// Shows the user-facing message for [error].
  static void error(BuildContext context, Object error) =>
      show(context, errorMessage(error), tone: DSToastTone.error);
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    required this.tone,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final DSToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: DSMotion.medium, reverseDuration: DSMotion.fast);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // Leave time to reach for an action like Undo.
    _timer = Timer(Duration(milliseconds: widget.actionLabel == null ? 2600 : 4500), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (IconData icon, Color tint) = switch (widget.tone) {
      DSToastTone.neutral => (CupertinoIcons.info_circle_fill, colors.textSecondary),
      DSToastTone.success => (CupertinoIcons.checkmark_circle_fill, colors.success),
      DSToastTone.error => (CupertinoIcons.exclamationmark_circle_fill, colors.danger),
    };
    final curved = CurvedAnimation(parent: _controller, curve: DSMotion.emphasized);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + DSSpacing.xs,
      left: DSSpacing.page,
      right: DSSpacing.page,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(curved),
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (_) => _dismiss(),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(DSRadius.lg),
                      border: Border.all(color: colors.border, width: 0.5),
                      boxShadow: [BoxShadow(color: colors.shadow, blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: tint, size: 20),
                        const SizedBox(width: DSSpacing.sm),
                        Expanded(child: Text(widget.message, style: context.type.subheadline)),
                        if (widget.actionLabel != null)
                          CupertinoButton(
                            padding: const EdgeInsets.only(left: DSSpacing.sm),
                            minimumSize: const Size(0, 32),
                            onPressed: () {
                              widget.onAction?.call();
                              _dismiss();
                            },
                            child: Text(
                              widget.actionLabel!,
                              style: context.type.subheadline.copyWith(color: colors.accent, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
