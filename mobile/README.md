# DevSpace for iPhone

The native iOS app for DevSpace, built in Flutter. It shares the web app's product model (workspaces, folders, tasks, projects, notes, docs, drawings), but the UI is designed from scratch for iPhone. Everything is stored locally in SQLite and works offline.

## Run

```bash
flutter pub get
dart run build_runner build      # Freezed, json_serializable, Drift
flutter test
flutter run -d "iPhone 17"
```

Debug builds have to be started by `flutter run` or Xcode. iOS won't launch a debug Flutter build on its own.

## Docs

- [Development](docs/DEVELOPMENT.md): setup, tests, schema changes, the widget target and simulator debugging
- [Data model](docs/DATA_MODEL.md): tables, delete rules, validation and repeating tasks
- [Widgets](docs/WIDGETS.md): how the app and the widget extension share data and actions

## Architecture

```
lib/
  app/            App root, GoRouter, theme (design tokens), Riverpod composition root
    providers/    Repositories, services and the streams the UI watches
    shell/        Five-tab shell with a blurred tab bar (each tab keeps its own stack)
    theme/        DSColors / DSTypography ThemeExtensions, spacing, radii, motion
  core/
    database/     Drift schema (tables.dart) and AppDatabase with step-by-step migrations
    models/       Freezed domain models, JSON with epoch-ms timestamps like the web app
    repositories/ Storage-agnostic interfaces plus Drift implementations
    services/     Rules that span repositories (active workspace), haptics
    widgets/      Design-system primitives: DSPage, DSSection/DSRow, DSButton, sheets, dialogs, toasts
  features/       One folder per area (home, workspaces, settings, …)
  shared/         App-specific widgets, constants and extensions
```

- **Swappable data layer.** UI talks to repository interfaces. To sync with a backend, implement them over HTTP (or add a sync layer) and swap them in `app/providers/core_providers.dart`.
- **Wire-compatible data.** Column names, `YYYY-MM-DD` dates, epoch-millisecond timestamps and enum strings match the web app's Zod models. Rich text is stored with a `contentFormat` marker so web (Tiptap) and mobile (Quill) content can be converted.
- **Cascades in storage.** SQLite foreign keys do the cascading: deleting a workspace removes everything in it, and deleting a folder or project unlinks its items.
- **Migrations.** Bump `schemaVersion`, add a step to `_upgrades` in `app_database.dart`, then run `dart run drift_dev make-migrations` to snapshot the schema into `drift_schemas/`.
- **Reactive UI.** Drift `watch()` streams feed Riverpod `StreamProvider`s, so every screen updates as soon as its data changes.

## Home Screen widgets

Native WidgetKit widgets live in `ios/DevSpaceWidgets/` (SwiftUI):

| Widget | Sizes | What you can do without opening the app |
| --- | --- | --- |
| **Tasks** | small, medium, large, Lock Screen | Tick tasks off, start or pause the "up next" task, push it to tomorrow, move every overdue task to today, page through long lists, add a task. "Edit Widget" picks the list (Today, Upcoming, In Progress, All) and an optional project. |
| **Project** | small, medium, large | Progress ring, tick tasks off, move overdue tasks to today, add a task to that project. "Edit Widget" picks the project; otherwise the next one due is shown. |
| **Productivity** | small, medium, large, Lock Screen | Today's progress, streak, this week's completions and a 12-week activity grid. |
| **Deadlines** | small, medium, large, Lock Screen | Task and project deadlines for two weeks; tick tasks off or push them to tomorrow. |
| **Quick Capture** | small, medium, large | New task for today or tomorrow, new project, open My Tasks. |

**Control Center** (iOS 18+) gets **New Task** and **Today's Tasks** buttons, which also work on the Lock Screen and the Action button. Siri and Shortcuts get **Add Task** and **Show Today**.

- **Data.** Whenever tasks, projects, the workspace or the date change, the app writes a JSON snapshot (`lib/features/widgets/widget_snapshot.dart`, version 2) to the App Group `group.tech.magadh.devspace` and reloads WidgetKit. It holds every open task, completions from the last 12 weeks and every active project, so widgets work out Today, Overdue, streaks and paging themselves, and stay right after midnight without the app.
- **Actions.** Widget buttons run App Intents (`ios/Shared/DevSpaceIntents.swift`) in the widget extension: the change is applied to the snapshot straight away, so every widget shows it, and queued in the App Group (one key per action, so the app and widgets never overwrite each other). The app saves queued changes to its database on launch and whenever it returns to the foreground; completing a repeating task there schedules the next one. Until then, a snapshot the app writes keeps any unsaved widget changes layered on top.
- **Links.** `devspace://open/<tab>[/task/<id>]`, `devspace://project/<id>`, `devspace://capture/task[?due=today|tomorrow&project=<id>]`, `devspace://capture/project`.
- **Xcode target.** `tool/add_widget_target.rb` adds or updates the extension target (it is idempotent): `GEM_HOME=$(brew --prefix cocoapods)/libexec ruby tool/add_widget_target.rb`. On a real device, both targets need your team selected and the App Group enabled.
- **Simulator note.** On the iOS 27 simulator the Home Screen sometimes keeps showing a widget's previous look after you tap one of its buttons, until the widget is redrawn (swipe to another Home Screen page and back). The change itself is applied immediately; check this on a device.

## Roadmap

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Project setup, design system, navigation, local database, workspace management | Done |
| 2 | Home screen, task management, task detail | Done |
| 3 | WidgetKit widgets, App Group, App Intents, deep links | Done |
| 4 | Notes, rich-text editor, autosave | Next |
| 5 | Projects, documentation | |
| 6 | Drawing and whiteboard | |
| 7 | Global search, notifications, settings, performance, tests | |
