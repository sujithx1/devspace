# Developing DevSpace for iPhone

Everything you need to build, run, test and debug the Flutter app and its
WidgetKit extension.

## Requirements

- Flutter (stable) with Dart 3.13 or later
- Xcode with an iOS 17+ simulator; the app targets iOS 17.0
- CocoaPods from Homebrew, only for its `xcodeproj` Ruby library, which the
  widget target script uses

## First run

```bash
cd mobile
flutter pub get
dart run build_runner build    # Freezed, json_serializable and Drift code
flutter run -d "iPhone 17"
```

Run `build_runner` again after changing any `@freezed` model, a Drift table or
`app_database.dart`. Generated `*.g.dart` and `*.freezed.dart` files are
committed, so a fresh clone builds without this step.

Debug builds must be started by `flutter run` or Xcode. Launched any other way
(tapping the icon after the tool has detached, `simctl launch`), a debug build
shows a blank screen because it waits for the Flutter tool to attach.

## Tests and checks

```bash
flutter analyze
flutter test
```

| File | Covers |
| --- | --- |
| `test/data_layer_test.dart` | Workspaces, folders, preferences, cascades, workspace service rules |
| `test/task_data_test.dart` | Task and project repositories, subtasks, undo, repeating tasks, applying widget actions |
| `test/task_logic_test.dart` | Views, filters, sorting, labels and stats in `task_logic.dart` |
| `test/tasks_widget_test.dart` | Tasks and Home screens rendered against an in-memory database |
| `test/widget_snapshot_test.dart` | The widget snapshot shape, deep links and queued action parsing |

Widget tests use a real in-memory SQLite database. Drift streams need real
time to deliver, so those tests pump with `runAsync` (see `settle` in
`tasks_widget_test.dart`) instead of `pumpAndSettle`, which never settles while
a spinner is animating.

The Swift extension has no unit tests. Build it on its own to catch compile
errors quickly:

```bash
cd ios
xcodebuild -project Runner.xcodeproj -scheme DevSpaceWidgets \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

## Database changes

1. Edit `lib/core/database/tables.dart`.
2. Bump `schemaVersion` in `app_database.dart` and add a step to `_upgrades`
   keyed by the version you are upgrading from.
3. Run `dart run build_runner build`, then
   `dart run drift_dev make-migrations` to snapshot the new schema into
   `drift_schemas/`. It also generates schema helpers under `test/drift/`
   (set in `build.yaml`) for writing a migration test from the old version.

See [DATA_MODEL.md](DATA_MODEL.md) for the tables and their rules.

## The widget extension

The `DevSpaceWidgets` target is added to `ios/Runner.xcodeproj` by a script
rather than by hand, so it can be recreated if the project file is regenerated:

```bash
GEM_HOME=$(brew --prefix cocoapods)/libexec ruby tool/add_widget_target.rb
```

It is safe to re-run. When you add a Swift file to `ios/DevSpaceWidgets/` or
`ios/Shared/`, add its name to the lists in the script and run it again.
Files in `ios/Shared/` are compiled into both the app and the extension.

Widget changes need a full rebuild (`flutter run` again); hot reload only
affects Dart code. See [WIDGETS.md](WIDGETS.md) for how the app and the widgets
exchange data.

### Running on a device

Both the **Runner** and **DevSpaceWidgets** targets need your team selected and
the App Group `group.tech.magadh.devspace` enabled under Signing &
Capabilities. Without the App Group the widgets install but stay on "Open
DevSpace to get started".

## Debugging on the simulator

Find the app's database and inspect it with `sqlite3`:

```bash
SIM=booted
DB=$(find "$(xcrun simctl get_app_container $SIM tech.magadh.devspace data)" -name devspace.sqlite)
sqlite3 "$DB" "select title, status, due_date from tasks;"
```

Read what the widgets see (the snapshot, queued actions and page positions):

```bash
GROUP=$(xcrun simctl get_app_container $SIM tech.magadh.devspace group.tech.magadh.devspace)
xcrun simctl spawn $SIM defaults read "$GROUP/Library/Preferences/group.tech.magadh.devspace"
```

Open a deep link (iOS asks to confirm links opened this way; widget taps don't):

```bash
xcrun simctl openurl $SIM "devspace://capture/task?due=tomorrow"
```

Follow widget and App Intent logs:

```bash
xcrun simctl spawn $SIM log stream --style compact \
  --predicate 'process CONTAINS "DevSpaceWidgets"'
```

On the iOS 27 simulator a widget sometimes keeps showing its old look after one
of its buttons is tapped, even though the change was applied and the timeline
reloaded. Swiping to another Home Screen page and back redraws it.
