import 'package:flutter/cupertino.dart';

import '../../app/theme/app_theme.dart';
import '../errors/app_exception.dart';
import '../services/haptics.dart';

/// Native alert asking the user to confirm. Resolves to true on confirm.
Future<bool> showDSConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  if (destructive) Haptics.warning();
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        CupertinoDialogAction(isDefaultAction: !destructive, onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: destructive,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Alert with a single text field, like "New Folder" in Notes.
///
/// [onSubmit] runs when the user confirms; if it throws an [AppException] the
/// message is shown inside the alert and it stays open.
Future<T?> showDSTextPrompt<T>(
  BuildContext context, {
  required String title,
  String? message,
  String initialValue = '',
  String? placeholder,
  required String confirmLabel,
  required Future<T> Function(String value) onSubmit,
}) {
  return showCupertinoDialog<T>(
    context: context,
    builder: (context) => _TextPromptDialog<T>(
      title: title,
      message: message,
      initialValue: initialValue,
      placeholder: placeholder,
      confirmLabel: confirmLabel,
      onSubmit: onSubmit,
    ),
  );
}

class _TextPromptDialog<T> extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.message,
    required this.initialValue,
    required this.placeholder,
    required this.confirmLabel,
    required this.onSubmit,
  });

  final String title;
  final String? message;
  final String initialValue;
  final String? placeholder;
  final String confirmLabel;
  final Future<T> Function(String value) onSubmit;

  @override
  State<_TextPromptDialog<T>> createState() => _TextPromptDialogState<T>();
}

class _TextPromptDialogState<T> extends State<_TextPromptDialog<T>> {
  late final _controller = TextEditingController(text: widget.initialValue)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initialValue.length);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onSubmit(_controller.text);
      Haptics.success();
      if (mounted) Navigator.pop(context, result);
    } on AppException catch (e) {
      Haptics.warning();
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(widget.message!)),
          const SizedBox(height: DSSpacing.xs),
          CupertinoTextField(
            controller: _controller,
            autofocus: true,
            placeholder: widget.placeholder,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            maxLength: 60,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: context.type.footnote.copyWith(color: colors.danger)),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: value.text.trim().isEmpty || _busy ? null : _submit,
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}

class DSSheetAction<T> {
  const DSSheetAction({required this.label, required this.value, this.destructive = false});

  final String label;
  final T value;
  final bool destructive;
}

/// Native action sheet. Resolves to the chosen action's value, or null on cancel.
Future<T?> showDSActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<DSSheetAction<T>> actions,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: [
        for (final a in actions)
          CupertinoActionSheetAction(
            isDestructiveAction: a.destructive,
            onPressed: () => Navigator.pop(context, a.value),
            child: Text(a.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ),
  );
}
