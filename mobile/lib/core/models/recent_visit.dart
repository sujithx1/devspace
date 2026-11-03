import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'json_converters.dart';

part 'recent_visit.freezed.dart';
part 'recent_visit.g.dart';

/// One row per opened entity; [id] is `"$entityType:$entityId"`.
@freezed
abstract class RecentVisit with _$RecentVisit {
  const factory RecentVisit({
    required String id,
    required String workspaceId,
    required EntityType entityType,
    required String entityId,
    @EpochMillisConverter() required DateTime visitedAt,
  }) = _RecentVisit;

  factory RecentVisit.fromJson(Map<String, dynamic> json) => _$RecentVisitFromJson(json);
}
