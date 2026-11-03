import 'package:json_annotation/json_annotation.dart';

/// Timestamps travel as epoch milliseconds, matching the web app's models.
class EpochMillisConverter implements JsonConverter<DateTime, int> {
  const EpochMillisConverter();

  @override
  DateTime fromJson(int json) => DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

class NullableEpochMillisConverter implements JsonConverter<DateTime?, int?> {
  const NullableEpochMillisConverter();

  @override
  DateTime? fromJson(int? json) => json == null ? null : DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int? toJson(DateTime? object) => object?.millisecondsSinceEpoch;
}
