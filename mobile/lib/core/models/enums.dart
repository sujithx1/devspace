import 'package:json_annotation/json_annotation.dart';

/// Every enum carries the exact string used by the web app (its `wire` value),
/// which is what we store in SQLite and send over JSON.
mixin WireEnum on Enum {
  String get wire;
}

T _fromWire<T extends WireEnum>(List<T> values, String? wire, T fallback) =>
    values.firstWhere((v) => v.wire == wire, orElse: () => fallback);

@JsonEnum(valueField: 'wire')
enum WorkspaceType with WireEnum {
  personal('private'),
  group('group');

  const WorkspaceType(this.wire);
  @override
  final String wire;

  static WorkspaceType fromWire(String? wire) => _fromWire(values, wire, personal);
}

/// What a folder holds. Notes, docs and drawings each have their own folders.
@JsonEnum(valueField: 'wire')
enum FolderKind with WireEnum {
  note('note'),
  doc('doc'),
  drawing('drawing');

  const FolderKind(this.wire);
  @override
  final String wire;

  static FolderKind fromWire(String? wire) => _fromWire(values, wire, note);
}

@JsonEnum(valueField: 'wire')
enum EntityType with WireEnum {
  note('note'),
  doc('doc'),
  task('task'),
  project('project'),
  drawing('drawing');

  const EntityType(this.wire);
  @override
  final String wire;

  static EntityType fromWire(String? wire) => _fromWire(values, wire, note);
}

@JsonEnum(valueField: 'wire')
enum TaskStatus with WireEnum {
  todo('todo', 'To Do'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed');

  const TaskStatus(this.wire, this.label);
  @override
  final String wire;
  final String label;

  static TaskStatus fromWire(String? wire) => _fromWire(values, wire, todo);
}

/// Shared by tasks and projects. [rank] orders by importance, highest first.
@JsonEnum(valueField: 'wire')
enum Priority with WireEnum {
  low('low', 'Low', 0),
  medium('medium', 'Medium', 1),
  high('high', 'High', 2),
  urgent('urgent', 'Urgent', 3);

  const Priority(this.wire, this.label, this.rank);
  @override
  final String wire;
  final String label;
  final int rank;

  static Priority fromWire(String? wire) => _fromWire(values, wire, medium);
}

@JsonEnum(valueField: 'wire')
enum Recurrence with WireEnum {
  daily('daily', 'Every Day'),
  weekdays('weekdays', 'Every Weekday'),
  weekly('weekly', 'Every Week'),
  monthly('monthly', 'Every Month'),
  yearly('yearly', 'Every Year');

  const Recurrence(this.wire, this.label);
  @override
  final String wire;
  final String label;

  static Recurrence? tryWire(String? wire) => values.where((v) => v.wire == wire).firstOrNull;
}

@JsonEnum(valueField: 'wire')
enum ProjectStatus with WireEnum {
  planning('planning', 'Planning'),
  active('active', 'Active'),
  onHold('on_hold', 'On Hold'),
  completed('completed', 'Completed');

  const ProjectStatus(this.wire, this.label);
  @override
  final String wire;
  final String label;

  static ProjectStatus fromWire(String? wire) => _fromWire(values, wire, planning);
}

/// Project colours; names match the web app and map to the UI palette.
enum ProjectColor with WireEnum {
  indigo,
  emerald,
  amber,
  rose,
  sky,
  violet,
  zinc;

  @override
  String get wire => name;

  static ProjectColor fromWire(String? wire) => _fromWire(values, wire, indigo);
}
