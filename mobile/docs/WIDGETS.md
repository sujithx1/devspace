# Widgets: how the app and the widget extension talk

The Home Screen widgets, Lock Screen widgets and Control Center buttons run in
the `DevSpaceWidgets` extension, a separate process that cannot open the app's
SQLite database. The two sides share data through the App Group
`group.tech.magadh.devspace`, using `UserDefaults(suiteName:)`.

```
 Flutter app                         App Group (UserDefaults)          Widget extension
 ───────────                         ────────────────────────          ────────────────
 widget_sync.dart ── saveSnapshot ─▶ widget.snapshot.v1  ─────────────▶ DevSpaceProvider
                  ◀─ takeActions ─── widget.action.<time>.<uuid> ◀──── App Intents
                                     widget.page.<key>   ◀───────────▶ NextPageIntent
```

| Piece | File |
| --- | --- |
| Builds the snapshot | `lib/features/widgets/widget_snapshot.dart` |
| Publishes it, applies queued actions | `lib/features/widgets/widget_sync.dart` |
| Method channel (Dart side) | `lib/core/services/widget_bridge.dart` |
| Method channel and URL handling (iOS side) | `ios/Runner/WidgetBridge.swift` |
| App Group storage, shared by both targets | `ios/Shared/DevSpaceShared.swift` |
| Snapshot models (Swift) | `ios/Shared/WidgetModels.swift` |
| Widget actions | `ios/Shared/DevSpaceIntents.swift` |
| Today, Overdue, streak and paging logic | `ios/DevSpaceWidgets/DayModel.swift` |

## The snapshot (version 2)

The app rewrites the snapshot whenever tasks, projects, the active workspace
or the date change (debounced by 300 ms), then calls
`WidgetCenter.reloadAllTimelines()`. It covers the active workspace only.

```json
{
  "version": 2,
  "generatedAt": 1794131538249,
  "workspace": { "name": "Personal", "icon": "🚀" },
  "tasks": [
    {
      "id": "…", "title": "Fix flaky test",
      "due": "2026-11-06", "time": "09:30",
      "priority": "urgent", "status": "in_progress", "completedAt": null,
      "projectId": "…", "project": "Launch", "projectColor": "violet",
      "repeats": false
    }
  ],
  "projects": [
    {
      "id": "…", "name": "Launch", "due": "2026-11-12", "color": "violet",
      "status": "active", "priority": "high",
      "progress": 0.4, "openTasks": 3, "totalTasks": 5
    }
  ]
}
```

- **Tasks:** every open task, most pressing first (capped at 200), then tasks
  completed in the last 12 weeks, newest first (capped at 400).
- **Projects:** every project that isn't completed, soonest due first.
- **Values** use the app's wire formats: `YYYY-MM-DD` local dates, `HH:mm`
  times, epoch-millisecond timestamps and the same enum strings as the database.

The snapshot holds raw dates rather than ready-made lists, so widgets work out
Today, Overdue and Upcoming for the moment they render. Each timeline has
entries for now and the next two midnights, so the lists roll over without the
app running.

To change the shape: bump `widgetSnapshotVersion`, update `WidgetModels.swift`
to match, and make new Swift fields optional so a snapshot written by an older
app still decodes.

## Actions

Widget buttons run App Intents inside the extension. Each one changes the
snapshot straight away, so every DevSpace widget shows the change, and queues
the change for the app.

| Intent | Used by | Effect |
| --- | --- | --- |
| `SetTaskCompletedIntent` | Checkboxes | Tick or untick a task |
| `SetTaskStatusIntent` | Start, Pause, Done | Set status to `todo`, `in_progress` or `completed` |
| `RescheduleTaskIntent` | Tomorrow | Move the due date to today plus N days |
| `RescheduleOverdueIntent` | Move to Today | Move every overdue task (or one project's) to today |
| `NextPageIntent` | `1–3 of 8` pager | Show the next page; changes no task data |
| `OpenDevSpaceIntent` | +, Quick Capture, controls | Open the app at a `devspace://` destination |

### Queue

Each action is stored under its own key,
`widget.action.<15-digit epoch ms>.<uuid>`, holding a JSON object. Separate keys
mean the app and the extension never overwrite each other's queue;
`UserDefaults` has no atomic read-modify-write. Keys sort into the order the
actions happened.

```json
{ "type": "update", "taskId": "…", "status": "in_progress", "at": 1794131383711 }
{ "type": "update", "taskId": "…", "due": "2026-11-11", "at": 1794131383711 }
{ "type": "url", "url": "devspace://capture/task?due=tomorrow" }
```

Version 1 used `{ "type": "complete", "taskId": "…", "completed": true }` in a
single array under `widget.pendingActions.v1`. Both are still read.

### Applying actions

The app takes the whole queue on launch, whenever it returns to the
foreground, and when the iOS side signals `actionsAvailable` over the method
channel. Each task update goes through the same repository and service as an
edit made in the app, so completing a repeating task from a widget schedules
its next occurrence. A task deleted in the app since is skipped, and a failing
action is reported without blocking the others. Afterwards the app writes a
fresh snapshot.

While actions are still queued, a snapshot the app writes has them layered
back on top (`DevSpaceShared.saveSnapshotJSON`), so a widget never flips back
to the old state before the app has caught up.

### Reloads

iOS pauses reloads for a widget while one of its intents runs, then reloads
that widget. Intents also ask every DevSpace widget to reload and wait 250 ms,
so the request lands during the pause rather than racing the system's own
reload.

## Paging

Long lists show one page at a time. The page number is stored in
`widget.page.<key>`, where the key names the list and the widget size, so a
medium and a large widget of the same list page independently:

- `tasks.<list>.<projectId or all>.m` and `.l`
- `project.<projectId>.m` and `.l`
- `deadlines.m` and `deadlines.l`

## Links

| URL | Opens |
| --- | --- |
| `devspace://open/home` (or `tasks`, `projects`, `notes`, `more`) | That tab |
| `devspace://open/tasks/task/<id>` | A task's detail screen |
| `devspace://project/<id>` | The Projects tab and that project's editor |
| `devspace://capture/task` | New Task, due today |
| `devspace://capture/task?due=tomorrow` | New Task, due tomorrow (`due=none` for no date) |
| `devspace://capture/task?project=<id>` | New Task in that project, no date unless `due` is given |
| `devspace://capture/project` | New Project |

`open` paths are checked against a fixed pattern; anything else is ignored.
Links that open a sheet wait until the app is fully in the foreground, so the
title field gets keyboard focus.

## Widget kinds

`TodayTasksWidget` (shown as **Tasks**), `ProjectWidget`,
`ProductivityWidget`, `UpcomingDeadlinesWidget` (**Deadlines**) and
`QuickCaptureWidget`. On iOS 18 and later the bundle also contains the
controls `tech.magadh.devspace.NewTaskControl` and
`tech.magadh.devspace.TodayControl`. Renaming a kind removes that widget from
people's Home Screens, so keep these stable.
