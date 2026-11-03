# DevSpace

A local-first, all-in-one workspace for developers: notes, tasks, projects, technical docs and whiteboards in one app. Everything persists in the browser (IndexedDB). There's no backend and no account.

## Getting started

```bash
npm install
npm run dev        # http://localhost:5173
npm test           # unit + repository tests (fake IndexedDB)
npm run typecheck
npm run build
```

`predev`/`prebuild` copy Excalidraw's fonts into `public/excalidraw-assets/` so the whiteboard works offline.

## Features

| Area | What works |
| --- | --- |
| Workspaces | Create, rename, switch, delete. Each workspace is **Private** (just you) or **Group** (members with owner/editor/viewer roles and task assignment), and can be switched either way in Settings. Onboarding on first run. JSON backup export/import (Settings). |
| Notes & Docs | Tiptap editor: headings, lists, checklists, quotes, links (⌘K), images (upload, paste, drop, URL), code blocks with syntax highlighting and a language picker. Markdown shortcuts. Autosave with a status indicator. Folders (drag a page onto a folder, or use the menu), pinning, tags, project links, duplicate, delete, filter/sort/search. Export or copy as Markdown. |
| Tasks | Assignees in group workspaces (avatar on cards, "Assign to" menu, assignee filter). Kanban board (Todo / In Progress / Completed) with drag-and-drop between and within columns (mouse and keyboard). List view, inline quick-add, priorities, due dates (overdue highlighting), descriptions, project links. Search plus filters for priority, due window and project. |
| Projects | Status, priority, colour, start/due dates (validated), description. Progress from linked tasks. Detail page with a project board and linked notes/docs/drawings (create new or link existing). |
| Drawings | Excalidraw canvas: pen, eraser, selection/move, rectangle, ellipse, diamond, arrow, line, text, colours, stroke width, undo/redo, zoom/pan, grid. Autosave, thumbnails, PNG/SVG export, folders, project links. |
| Dashboard | Greeting, quick-create, task stats (open, completion rate, completed this week, overdue), pending tasks, recently opened, active projects, recent notes/docs and drawings. |
| Search | ⌘K command palette (search plus commands) and a full search page across notes, docs, tasks, projects and drawing text, with type filters and highlighted matches. |
| UX | Light/dark/system theme, collapsible sidebar, mobile drawer, context menus, toasts, confirm dialogs, loading/empty/error states, and keyboard shortcuts (press `?`). |

## Architecture

```
src/
  data/                 Domain + persistence (no React)
    models.ts           Zod schemas → TypeScript types (single source of truth)
    repositories.ts     Storage-agnostic repository interfaces
    dexie/              IndexedDB implementation (Dexie) incl. cascades
    backup.ts           Export/import via repository interfaces
    index.ts            Composition root: `createRepositories()`
  stores/               Zustand: one collection store per entity, plus UI, toasts, dialogs, menus
  features/<feature>/   Feature UI + business actions (`*Actions.ts`) + pure logic (`*Logic.ts`)
  components/           Reusable UI primitives and layout (sidebar, palette, header)
  lib/                  Utilities, routes, display metadata
```

- **The data layer can be swapped out.** UI and stores depend only on the `Repositories` interfaces. To move to a backend, implement those interfaces with HTTP calls and return them from `createRepositories()` in `src/data/index.ts`. Nothing else imports Dexie.
- **Validation happens in one place.** Every write goes through Zod in the repository and raises a `ValidationError` with per-field messages that forms display inline.
- **Writes are optimistic.** Collection stores update in-memory state immediately, persist through the repository, and roll back on failure. A per-entity write sequence stops slow older writes from overwriting newer edits.
- **Roles are enforced in the stores.** In a group workspace you pick who you're acting as ("Switch user" in the sidebar). Viewers are read-only; editors can change content but not members or workspace settings; owners can do everything. Every store write runs `checkPermission`, so blocked actions fail whether they come from a button, a shortcut or the palette, and the UI hides what the role can't do. Without a backend this is a local simulation: anyone using the browser can switch user.
- **Membership rules live in storage too.** A group workspace always keeps at least one owner, member emails are unique per workspace, and removing a member unassigns their tasks. Members and roles are stored locally; sign-in, invites and enforcing roles need the future backend.
- **Cascades live in storage.** Deleting a project unlinks its tasks, pages and drawings. Deleting a folder moves its items to the top level. Deleting a workspace removes everything in it. A backend would own these rules the same way.
- **Business logic is separate from UI.** Actions (create/duplicate/delete with confirmation and toasts) live in `features/*/…Actions.ts`. Ranking, filtering, ordering and progress are pure functions with unit tests.
- **Heavy modules load lazily.** The editor (Tiptap + highlight.js grammars) and Excalidraw load only when first used.

## Keyboard shortcuts

`⌘K` palette · `⌘\` sidebar · `⌘⇧L` theme · `?` help · `Alt+N/T/P/D/W` new note/task/project/doc/drawing · `G` then `H/N/T/P/D/W` to navigate. Board cards: `Space` picks up/drops, arrow keys move, `Enter` opens.
