import 'package:devspace/app/providers/core_providers.dart';
import 'package:devspace/app/theme/app_theme.dart';
import 'package:devspace/core/database/app_database.dart';
import 'package:devspace/core/models/enums.dart';
import 'package:devspace/core/utils/dates.dart';
import 'package:devspace/features/home/home_screen.dart';
import 'package:devspace/features/tasks/tasks_screen.dart';
import 'package:devspace/features/tasks/widgets/task_checkbox.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders real screens against an in-memory database seeded through the
/// same repositories the app uses.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late String workspaceId;

  /// Lets database streams deliver (they need real time) and animations run.
  /// Avoids pumpAndSettle, which never settles while a spinner is showing.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: screen),
      ),
    );
    await settle(tester);
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    final ws = await container.read(workspaceServiceProvider).create(name: 'Test');
    workspaceId = ws.id;
    final tasks = container.read(taskRepositoryProvider);
    final project = await container.read(projectRepositoryProvider).create(
      workspaceId: ws.id,
      name: 'Launch',
      status: ProjectStatus.active,
    );
    final today = Dates.dateOnly(DateTime.now());
    await tasks.create(workspaceId: ws.id, title: 'Ship the build', dueDate: Dates.toIso(today), projectId: project.id);
    await tasks.create(
      workspaceId: ws.id,
      title: 'Fix crash',
      dueDate: Dates.toIso(Dates.addDays(today, -2)),
      priority: Priority.urgent,
    );
    await tasks.create(workspaceId: ws.id, title: 'Plan sprint', dueDate: Dates.toIso(Dates.addDays(today, 3)));
  });

  tearDown(() => db.close());

  /// Unmounts the screen and disposes the container inside the test, so its
  /// timers (e.g. the midnight rollover) are gone before the test ends.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await settle(tester);
  }

  testWidgets('Tasks: Today shows overdue and today; Upcoming shows the future', (tester) async {
    await pumpScreen(tester, const TasksScreen());
    await settle(tester);

    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Fix crash'), findsOneWidget);
    expect(find.text('Ship the build'), findsOneWidget);
    expect(find.text('Plan sprint'), findsNothing);
    expect(find.text('Launch'), findsOneWidget); // project shown on the row

    await tester.tap(find.text('Upcoming'));
    await settle(tester);
    expect(find.text('Plan sprint'), findsOneWidget);
    expect(find.text('Fix crash'), findsNothing);
    await finish(tester);
  });

  testWidgets('Tasks: search filters the list', (tester) async {
    await pumpScreen(tester, const TasksScreen());
    await tester.tap(find.text('All'));
    await settle(tester);
    await tester.enterText(find.byType(CupertinoSearchTextField), 'crash');
    await settle(tester);
    expect(find.text('Fix crash'), findsOneWidget);
    expect(find.text('Ship the build'), findsNothing);
    await finish(tester);
  });

  testWidgets('Tasks: ticking the checkbox completes the task', (tester) async {
    await pumpScreen(tester, const TasksScreen());
    final checkbox = find.descendant(
      of: find.ancestor(of: find.text('Ship the build'), matching: find.byType(Row)).first,
      matching: find.byType(TaskCheckbox),
    );
    await tester.tap(checkbox);
    // The tick shows briefly before the task is saved and leaves Today.
    await tester.pump(const Duration(milliseconds: 700));
    await settle(tester);
    expect(find.text('Ship the build'), findsNothing);

    final stored = await tester.runAsync(() => container.read(taskRepositoryProvider).watchByWorkspace(workspaceId).first);
    expect(stored!.firstWhere((t) => t.title == 'Ship the build').isCompleted, isTrue);
    await finish(tester);
  });

  testWidgets('Home: shows progress, overdue, today and active projects', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    await settle(tester);
    expect(find.text('0 of 2 done today'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Today'), findsWidgets); // section header and due label
    expect(find.text('Coming Up'), findsOneWidget);
    expect(find.text('Plan sprint'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Active Projects'), 200);
    expect(find.text('Active Projects'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('Icon-only buttons show their name when held', (tester) async {
    await pumpScreen(tester, const TasksScreen());
    expect(find.text('Sort and filter'), findsNothing);
    await tester.longPress(find.byIcon(CupertinoIcons.line_horizontal_3_decrease_circle));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sort and filter'), findsOneWidget);
    // It hides itself again.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Sort and filter'), findsNothing);
    await finish(tester);
  });
}
