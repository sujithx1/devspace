import 'package:devspace/core/database/app_database.dart';
import 'package:devspace/core/errors/app_exception.dart';
import 'package:devspace/core/models/enums.dart';
import 'package:devspace/core/models/workspace.dart';
import 'package:devspace/core/repositories/folder_repository.dart';
import 'package:devspace/core/repositories/preferences_repository.dart';
import 'package:devspace/core/repositories/recent_repository.dart';
import 'package:devspace/core/repositories/workspace_repository.dart';
import 'package:devspace/core/services/workspace_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftWorkspaceRepository workspaces;
  late DriftFolderRepository folders;
  late DriftPreferencesRepository prefs;
  late DriftRecentRepository recents;
  late WorkspaceService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    workspaces = DriftWorkspaceRepository(db);
    folders = DriftFolderRepository(db);
    prefs = DriftPreferencesRepository(db);
    recents = DriftRecentRepository(db);
    service = WorkspaceService(workspaces, prefs);
  });

  tearDown(() => db.close());

  group('WorkspaceRepository', () {
    test('creates with trimmed name and default icon', () async {
      final w = await workspaces.create(name: '  Side Projects  ');
      expect(w.name, 'Side Projects');
      expect(w.icon, '🚀');
      expect(w.type, WorkspaceType.personal);
      expect(await workspaces.get(w.id), w);
    });

    test('rejects empty and overlong names', () async {
      expect(() => workspaces.create(name: '   '), throwsA(isA<ValidationException>()));
      expect(() => workspaces.create(name: 'x' * 61), throwsA(isA<ValidationException>()));
    });

    test('update keeps createdAt and bumps updatedAt', () async {
      final w = await workspaces.create(name: 'A');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final updated = await workspaces.update(w.id, name: 'B', icon: '🧠');
      expect(updated.name, 'B');
      expect(updated.icon, '🧠');
      expect(updated.createdAt, w.createdAt);
      expect(updated.updatedAt.isAfter(w.updatedAt), isTrue);
    });

    test('update of a missing workspace throws NotFoundException', () async {
      expect(() => workspaces.update('nope', name: 'X'), throwsA(isA<NotFoundException>()));
    });

    test('delete cascades to everything inside the workspace', () async {
      final w = await workspaces.create(name: 'Doomed');
      final keep = await workspaces.create(name: 'Keep');
      await folders.create(workspaceId: w.id, kind: FolderKind.note, name: 'Inbox');
      await recents.touch(workspaceId: w.id, type: EntityType.note, entityId: 'n1');
      final ts = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.tasks).insert(
        TasksCompanion.insert(id: 't1', workspaceId: w.id, title: 'Task', createdAt: ts, updatedAt: ts),
      );
      await db.into(db.subtasks).insert(
        SubtasksCompanion.insert(id: 's1', taskId: 't1', title: 'Sub', createdAt: ts, updatedAt: ts),
      );
      await db.into(db.tasks).insert(
        TasksCompanion.insert(id: 't2', workspaceId: keep.id, title: 'Other', createdAt: ts, updatedAt: ts),
      );

      await workspaces.delete(w.id);

      expect(await db.select(db.folders).get(), isEmpty);
      expect(await db.select(db.recentVisits).get(), isEmpty);
      expect(await db.select(db.subtasks).get(), isEmpty);
      expect((await db.select(db.tasks).get()).map((t) => t.id), ['t2']);
    });

    test('watchStats counts items and reacts to changes', () async {
      final w = await workspaces.create(name: 'Stats');
      final stream = workspaces.watchStats(w.id);
      expect(await stream.first, const WorkspaceStats());

      final ts = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.tasks).insert(
        TasksCompanion.insert(id: 't1', workspaceId: w.id, title: 'Open', createdAt: ts, updatedAt: ts),
      );
      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: 't2',
          workspaceId: w.id,
          title: 'Done',
          status: const Value('completed'),
          createdAt: ts,
          updatedAt: ts,
        ),
      );
      await folders.create(workspaceId: w.id, kind: FolderKind.doc, name: 'Specs');

      final stats = await stream.first;
      expect(stats.tasks, 2);
      expect(stats.openTasks, 1);
      expect(stats.folders, 1);
    });
  });

  group('FolderRepository', () {
    late Workspace w;
    setUp(() async => w = await workspaces.create(name: 'W'));

    test('names are unique per kind, case-insensitively', () async {
      await folders.create(workspaceId: w.id, kind: FolderKind.note, name: 'Ideas');
      expect(
        () => folders.create(workspaceId: w.id, kind: FolderKind.note, name: 'ideas'),
        throwsA(isA<ValidationException>()),
      );
      // Same name in another kind is fine.
      await folders.create(workspaceId: w.id, kind: FolderKind.doc, name: 'Ideas');
    });

    test('rename validates and allows keeping its own name', () async {
      final a = await folders.create(workspaceId: w.id, kind: FolderKind.note, name: 'A');
      await folders.create(workspaceId: w.id, kind: FolderKind.note, name: 'B');
      expect((await folders.rename(a.id, 'a')).name, 'a');
      expect(() => folders.rename(a.id, 'B'), throwsA(isA<ValidationException>()));
    });

    test('deleting a folder moves its pages to the top level', () async {
      final f = await folders.create(workspaceId: w.id, kind: FolderKind.note, name: 'F');
      final ts = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.pages).insert(
        PagesCompanion.insert(
          id: 'p1',
          workspaceId: w.id,
          kind: 'note',
          folderId: Value(f.id),
          createdAt: ts,
          updatedAt: ts,
        ),
      );
      await folders.delete(f.id);
      final page = await db.select(db.pages).getSingle();
      expect(page.folderId, isNull);
    });

    test('watchByWorkspace filters by kind and sorts by name', () async {
      await folders.create(workspaceId: w.id, kind: FolderKind.note, name: 'beta');
      await folders.create(workspaceId: w.id, kind: FolderKind.note, name: 'Alpha');
      await folders.create(workspaceId: w.id, kind: FolderKind.drawing, name: 'Sketches');
      final notes = await folders.watchByWorkspace(w.id, kind: FolderKind.note).first;
      expect(notes.map((f) => f.name), ['Alpha', 'beta']);
    });
  });

  group('WorkspaceService', () {
    test('create switches to the new workspace', () async {
      final a = await service.create(name: 'A');
      expect(await prefs.get(PreferenceKey.activeWorkspaceId), a.id);
      final b = await service.create(name: 'B');
      expect(await prefs.get(PreferenceKey.activeWorkspaceId), b.id);
    });

    test('refuses to delete the last workspace', () async {
      final a = await service.create(name: 'Only');
      expect(() => service.delete(a.id), throwsA(isA<ValidationException>()));
      expect(await workspaces.get(a.id), isNotNull);
    });

    test('deleting the active workspace activates another', () async {
      final a = await service.create(name: 'A');
      final b = await service.create(name: 'B');
      await service.delete(b.id);
      expect(await prefs.get(PreferenceKey.activeWorkspaceId), a.id);
    });

    test('deleting an inactive workspace keeps the active one', () async {
      final a = await service.create(name: 'A');
      final b = await service.create(name: 'B');
      await service.switchTo(a.id);
      await service.delete(b.id);
      expect(await prefs.get(PreferenceKey.activeWorkspaceId), a.id);
    });
  });

  test('models round-trip through JSON with epoch-millisecond timestamps', () async {
    final w = await workspaces.create(name: 'Json', icon: '🧪');
    final json = w.toJson();
    expect(json['createdAt'], isA<int>());
    expect(json['type'], 'private');
    expect(Workspace.fromJson(json), w);
  });
}
