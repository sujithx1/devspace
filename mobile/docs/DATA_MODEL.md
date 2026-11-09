# Data model

All data lives in one SQLite database, `devspace.sqlite`, in the app's
Documents folder. The schema is defined with Drift in
`lib/core/database/tables.dart` and is at version 1.

Values use the same formats as the web app's Zod models, so a future sync
layer can map rows one to one:

- **IDs:** UUID v4 strings.
- **Timestamps:** epoch milliseconds (`created_at`, `updated_at`,
  `completed_at`, `visited_at`).
- **Dates:** local calendar days as `YYYY-MM-DD` text, so they never shift
  across time zones. Times are `HH:mm`.
- **Enums:** lowercase strings (`todo`, `in_progress`, `completed`; `low` to
  `urgent`; `planning`, `active`, `on_hold`, `completed`).
- **Lists:** tags are stored as a JSON array of strings.

## Tables

| Table | Holds | Belongs to |
| --- | --- | --- |
| `workspaces` | Name, emoji icon, type (`private` or `group`) | — |
| `folders` | Named folders for notes, docs or drawings (`kind`) | Workspace |
| `projects` | Name, description, status, priority, colour, start and due dates | Workspace |
| `tasks` | Title, notes, status, priority, due date and time, repeat rule, tags, sort order, completion time | Workspace, optional project |
| `subtasks` | Title, done flag, sort order | Task |
| `pages` | Notes and docs (`kind`), editor content, plain-text copy, tags, pinned | Workspace, optional folder and project |
| `drawings` | Title, scene JSON, thumbnail | Workspace, optional folder and project |
| `recent_visits` | Recently opened items, one row per item (`<type>:<id>`) | Workspace |
| `preferences` | Key–value settings: `activeWorkspaceId`, `themeMode`, `displayName` | — |

`pages.content` is stored with a `content_format` (`quill_delta` on mobile) so
web (Tiptap) and mobile content can be told apart and converted later.

## What happens on delete

Foreign keys are on, and the database does the cascading:

| Deleting | Also |
| --- | --- |
| A workspace | Deletes everything inside it |
| A project | Keeps its tasks, pages and drawings, without a project |
| A folder | Keeps its pages and drawings, at the top level |
| A task | Deletes its subtasks |

Deleting a task or project also removes it from `recent_visits`.

The workspace service refuses to delete the last workspace. If the active
workspace is deleted, the oldest remaining one becomes active.

## Validation

Every write goes through a repository, which validates and normalises input
and throws a `ValidationException` with per-field messages that forms show
inline.

| Field | Rule |
| --- | --- |
| Workspace name | Required, up to 60 characters |
| Folder name | Required, up to 60 characters, unique per workspace and kind (ignoring case) |
| Project name | Required, up to 80 characters; description up to 5,000 |
| Project dates | Due date on or after the start date |
| Task title | Required, up to 200 characters; notes up to 10,000 |
| Task due time | Only kept when the task has a due date |
| Tags | Up to 20 per task, each up to 32 characters; a leading `#` and duplicates are dropped |

Names and titles are trimmed. `completed_at` is set when a task is completed
and cleared when it's reopened.

## Repeating tasks

A task's `recurrence` is `daily`, `weekdays`, `weekly`, `monthly` or `yearly`.
Completing it (in the app or from a widget) creates the next occurrence on the
first matching day that is today or later, with the same details and its
subtasks unticked. The completed occurrence stops repeating, so it is never
scheduled twice. Monthly and yearly dates clamp to the end of shorter months
(Jan 31 → Feb 28).

## Code layout

- **Models** (`lib/core/models/`): Freezed classes with JSON in the web app's
  field names. Counts such as `subtaskCount` and a project's `taskCount` are
  filled in by repository queries and are never stored.
- **Repositories** (`lib/core/repositories/`): an interface plus a Drift
  implementation for each area. The UI only sees the interfaces, which are
  wired up in `lib/app/providers/core_providers.dart`; replace them there to
  add sync or a server.
- **Services** (`lib/core/services/`): rules that span repositories, such as
  the active workspace, repeating tasks and undoable deletes.
- **Streams:** repositories expose Drift `watch()` streams, which Riverpod
  providers turn into UI state, so screens and widgets update as soon as data
  changes.

See [DEVELOPMENT.md](DEVELOPMENT.md#database-changes) for how to change the
schema.
