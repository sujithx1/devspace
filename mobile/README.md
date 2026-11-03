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

## Roadmap

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Project setup, design system, navigation, local database, workspace management | Done |
| 2 | Home screen, task management, task detail | Done |
| 3 | WidgetKit widgets, App Group, App Intents, deep links | Next |
| 4 | Notes, rich-text editor, autosave | |
| 5 | Projects, documentation | |
| 6 | Drawing and whiteboard | |
| 7 | Global search, notifications, settings, performance, tests | |
