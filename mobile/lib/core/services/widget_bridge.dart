import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Something the user did outside the app that the app must apply: a task
/// ticked on a widget, or a deep link from a widget, shortcut or URL.
sealed class WidgetAction {
  const WidgetAction();

  static WidgetAction? fromJson(Map<String, dynamic> json) => switch (json['type']) {
    'complete' when json['taskId'] is String => CompleteTaskAction(
      taskId: json['taskId'] as String,
      completed: json['completed'] != false,
    ),
    'url' when json['url'] is String => OpenUrlAction(Uri.parse(json['url'] as String)),
    _ => null,
  };
}

final class CompleteTaskAction extends WidgetAction {
  const CompleteTaskAction({required this.taskId, required this.completed});

  final String taskId;
  final bool completed;
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
