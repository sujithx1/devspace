import 'dart:convert';

import 'package:drift/drift.dart';

/// SQLite schema. Column names and value formats follow the web app's models
/// (epoch-millisecond timestamps, `YYYY-MM-DD` dates, string enums) so a future
/// sync layer can map rows one-to-one.
///
/// Cascades live in storage, as they do on the web: deleting a workspace removes
/// everything inside it, deleting a project or folder unlinks its items.

/// JSON-encoded list of strings, used for tags.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) => (jsonDecode(fromDb) as List).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

mixin _Timestamps on Table {
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DataClassName('WorkspaceRow')
class Workspaces extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('🚀'))();
  TextColumn get type => text().withDefault(const Constant('private'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FolderRow')
@TableIndex(name: 'folders_workspace_kind', columns: {#workspaceId, #kind})
class Folders extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  TextColumn get name => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProjectRow')
@TableIndex(name: 'projects_workspace', columns: {#workspaceId})
class Projects extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('planning'))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get color => text().withDefault(const Constant('indigo'))();
  TextColumn get startDate => text().nullable()();
  TextColumn get dueDate => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskRow')
@TableIndex(name: 'tasks_workspace_status', columns: {#workspaceId, #status})
@TableIndex(name: 'tasks_workspace_due', columns: {#workspaceId, #dueDate})
@TableIndex(name: 'tasks_project', columns: {#projectId})
class Tasks extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get projectId => text().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('todo'))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get dueDate => text().nullable()();

  /// Optional `HH:mm` time on [dueDate]; mobile-only for now.
  TextColumn get dueTime => text().nullable()();

  /// `daily`, `weekdays`, `weekly` or `monthly`; null for one-off tasks.
  TextColumn get recurrence => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]')).map(const StringListConverter())();

  /// Position within a status column. Fractional for cheap inserts.
  RealColumn get sortOrder => real().withDefault(const Constant(0))();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SubtaskRow')
@TableIndex(name: 'subtasks_task', columns: {#taskId})
class Subtasks extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get taskId => text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  RealColumn get sortOrder => real().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Notes and documentation share one rich-text page shape, told apart by [kind].
@DataClassName('PageRow')
@TableIndex(name: 'pages_workspace_kind_updated', columns: {#workspaceId, #kind, #updatedAt})
class Pages extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();

  /// `note` or `doc`.
  TextColumn get kind => text()();
  TextColumn get folderId => text().nullable().references(Folders, #id, onDelete: KeyAction.setNull)();
  TextColumn get projectId => text().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Serialized editor document; [contentFormat] says how to read it.
  TextColumn get content => text().nullable()();
  TextColumn get contentFormat => text().withDefault(const Constant('quill_delta'))();

  /// Plain-text projection of [content] for search and previews.
  TextColumn get plainText => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant('[]')).map(const StringListConverter())();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DrawingRow')
@TableIndex(name: 'drawings_workspace_updated', columns: {#workspaceId, #updatedAt})
class Drawings extends Table with _Timestamps {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get folderId => text().nullable().references(Folders, #id, onDelete: KeyAction.setNull)();
  TextColumn get projectId => text().nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Engine-specific scene JSON, opaque to the data layer.
  TextColumn get scene => text().withDefault(const Constant('{}'))();
  BlobColumn get thumbnail => blob().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecentVisitRow')
@TableIndex(name: 'recents_workspace_visited', columns: {#workspaceId, #visitedAt})
@TableIndex(name: 'recents_entity', columns: {#entityId})
class RecentVisits extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get visitedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// App-level settings (theme, display name, active workspace).
@DataClassName('PreferenceRow')
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
