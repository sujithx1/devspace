import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/enums.dart';

/// Something the user did outside the app that the app must apply: a task
/// changed on a widget, or a deep link from a widget, control, shortcut or URL.
sealed class WidgetAction {
  const WidgetAction();

  static WidgetAction? fromJson(Map<String, dynamic> json) {
    final taskId = json['taskId'];
    return switch (json['type']) {
      // Version 1 widgets only ticked tasks.
      'complete' when taskId is String => UpdateTaskAction(
        taskId: taskId,
        status: json['completed'] == false ? TaskStatus.todo : TaskStatus.completed,
      ),
      'update' when taskId is String => UpdateTaskAction(
        taskId: taskId,
        status: TaskStatus.values.where((s) => s.wire == json['status']).firstOrNull,
        dueDate: json['due'] is String && _isoDate.hasMatch(json['due'] as String) ? json['due'] as String : null,
      ),
      'url' when json['url'] is String => OpenUrlAction(Uri.parse(json['url'] as String)),
      _ => null,
    };
  }

  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}

/// A task ticked, started, paused or rescheduled on a widget.
final class UpdateTaskAction extends WidgetAction {
  const UpdateTaskAction({required this.taskId, this.status, this.dueDate});

  final String taskId;
  final TaskStatus? status;

  /// New due day, `YYYY-MM-DD`.
  final String? dueDate;
}

final class OpenUrlAction extends WidgetAction {
  const OpenUrlAction(this.uri);

  final Uri uri;
}

/// Talks to the native side (`ios/Runner/WidgetBridge.swift`): publishes the
/// widget snapshot to the shared App Group and collects queued actions.
/// Every call is a no-op off iOS.
class WidgetBridge {
  WidgetBridge({MethodChannel? channel}) : _channel = channel ?? const MethodChannel('tech.magadh.devspace/widgets');

  final MethodChannel _channel;

  bool get isSupported => !kIsWeb && Platform.isIOS;

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    }
  }

  Future<void> saveSnapshot(Map<String, dynamic> snapshot) => _invoke<void>('saveSnapshot', jsonEncode(snapshot));

  Future<void> reloadWidgets() => _invoke<void>('reloadWidgets');

  /// Removes and returns every queued action, oldest first.
  Future<List<WidgetAction>> takeActions() async {
    final raw = await _invoke<String>('takeActions');
    if (raw == null || raw.isEmpty) return const [];
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) ?WidgetAction.fromJson(item),
    ];
  }

  /// [onActions] runs whenever the native side queues something new.
  void listen(VoidCallback onActions) {
    if (!isSupported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'actionsAvailable') onActions();
    });
  }

  void stopListening() {
    if (isSupported) _channel.setMethodCallHandler(null);
  }
}
