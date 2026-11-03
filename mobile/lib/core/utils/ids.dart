import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Globally unique, sync-safe identifier for any entity.
String newId() => _uuid.v4();

/// Current time truncated to milliseconds, the precision we persist.
DateTime nowMs() => DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);
