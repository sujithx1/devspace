import { z } from 'zod'

/**
 * Domain models for DevSpace.
 *
 * Every entity is described by a Zod schema, and its TypeScript type is inferred
 * from that schema, so validation and typing can never drift apart. The UI and
 * the stores only depend on these types, never on the storage engine.
 */

const id = z.string().min(1)
const timestamps = { createdAt: z.number(), updatedAt: z.number() }
const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Dates must be in YYYY-MM-DD format')
const name = (label: string, max = 120) =>
  z
    .string()
    .trim()
    .min(1, `${label} is required`)
    .max(max, `${label} must be ${max} characters or fewer`)

/** Tiptap/ProseMirror JSON. Kept opaque to the data layer. */
export const richContentSchema = z.record(z.string(), z.unknown())
export type RichContent = z.infer<typeof richContentSchema>

// ---------------------------------------------------------------------------
// Workspace
// ---------------------------------------------------------------------------

export const WORKSPACE_TYPES = ['private', 'group'] as const
export type WorkspaceType = (typeof WORKSPACE_TYPES)[number]

export const workspaceSchema = z.object({
  id,
  name: name('Workspace name', 60),
  icon: z.string().max(16).default('🚀'),
  /** Private workspaces are personal; group workspaces have members and task assignment. */
  type: z.enum(WORKSPACE_TYPES).default('private'),
  ...timestamps,
})
export type Workspace = z.infer<typeof workspaceSchema>
export const workspaceInputSchema = workspaceSchema.pick({ name: true, icon: true, type: true }).partial({ icon: true, type: true })
export type WorkspaceInput = z.input<typeof workspaceInputSchema>

// ---------------------------------------------------------------------------
// Member — a person in a group workspace
// ---------------------------------------------------------------------------

export const MEMBER_ROLES = ['owner', 'editor', 'viewer'] as const
export type MemberRole = (typeof MEMBER_ROLES)[number]

export const memberSchema = z.object({
  id,
  workspaceId: id,
  name: name('Member name', 60),
  email: z
    .string()
    .trim()
    .max(120)
    .refine((v) => v === '' || z.email().safeParse(v).success, 'Enter a valid email address')
    .default(''),
  role: z.enum(MEMBER_ROLES).default('editor'),
  ...timestamps,
})
export type Member = z.infer<typeof memberSchema>
export const memberInputSchema = memberSchema.pick({ workspaceId: true, name: true, email: true, role: true }).partial({ email: true, role: true })
export type MemberInput = z.input<typeof memberInputSchema>

// ---------------------------------------------------------------------------
// Folder — groups notes, docs or drawings inside a workspace
// ---------------------------------------------------------------------------

export const FOLDER_KINDS = ['note', 'doc', 'drawing'] as const
export type FolderKind = (typeof FOLDER_KINDS)[number]

export const folderSchema = z.object({
  id,
  workspaceId: id,
  kind: z.enum(FOLDER_KINDS),
  name: name('Folder name', 60),
  ...timestamps,
})
export type Folder = z.infer<typeof folderSchema>
export const folderInputSchema = folderSchema.pick({ workspaceId: true, kind: true, name: true })
export type FolderInput = z.input<typeof folderInputSchema>

// ---------------------------------------------------------------------------
// Pages: Notes and Documents share the same rich-text page shape
// ---------------------------------------------------------------------------

const pageShape = {
  id,
  workspaceId: id,
  folderId: id.nullable().default(null),
  projectId: id.nullable().default(null),
  title: z.string().trim().max(200, 'Title must be 200 characters or fewer').default(''),
  content: richContentSchema.nullable().default(null),
  /** Plain-text projection of `content`, used for search and previews. */
  plainText: z.string().default(''),
  tags: z.array(z.string().trim().min(1).max(32)).max(20).default([]),
  pinned: z.boolean().default(false),
  ...timestamps,
}

export const noteSchema = z.object(pageShape)
export type Note = z.infer<typeof noteSchema>

export const docSchema = z.object(pageShape)
export type Doc = z.infer<typeof docSchema>

export const pageInputSchema = z.object(pageShape).omit({ id: true, createdAt: true, updatedAt: true })
export type PageInput = z.input<typeof pageInputSchema>
export type Page = Note | Doc

// ---------------------------------------------------------------------------
// Task
// ---------------------------------------------------------------------------

export const TASK_STATUSES = ['todo', 'in_progress', 'completed'] as const
export type TaskStatus = (typeof TASK_STATUSES)[number]

export const PRIORITIES = ['low', 'medium', 'high', 'urgent'] as const
export type Priority = (typeof PRIORITIES)[number]

export const taskSchema = z.object({
  id,
  workspaceId: id,
  projectId: id.nullable().default(null),
  /** Member the task is assigned to (group workspaces only). */
  assigneeId: id.nullable().default(null),
  title: name('Task title', 200),
  description: z.string().max(10_000).default(''),
  status: z.enum(TASK_STATUSES).default('todo'),
  priority: z.enum(PRIORITIES).default('medium'),
  dueDate: isoDate.nullable().default(null),
  /** Sort position within a status column. Fractional to allow cheap inserts. */
  order: z.number().default(0),
  completedAt: z.number().nullable().default(null),
  ...timestamps,
})
export type Task = z.infer<typeof taskSchema>
export const taskInputSchema = taskSchema.omit({ id: true, createdAt: true, updatedAt: true, completedAt: true })
export type TaskInput = z.input<typeof taskInputSchema>

// ---------------------------------------------------------------------------
// Project
// ---------------------------------------------------------------------------

export const PROJECT_STATUSES = ['planning', 'active', 'on_hold', 'completed'] as const
export type ProjectStatus = (typeof PROJECT_STATUSES)[number]

export const PROJECT_COLORS = ['indigo', 'emerald', 'amber', 'rose', 'sky', 'violet', 'zinc'] as const
export type ProjectColor = (typeof PROJECT_COLORS)[number]

export const projectSchema = z
  .object({
    id,
    workspaceId: id,
    name: name('Project name', 80),
    description: z.string().max(5_000).default(''),
    status: z.enum(PROJECT_STATUSES).default('planning'),
    priority: z.enum(PRIORITIES).default('medium'),
    startDate: isoDate.nullable().default(null),
    dueDate: isoDate.nullable().default(null),
    color: z.enum(PROJECT_COLORS).default('indigo'),
    ...timestamps,
  })
  .refine((p) => !p.startDate || !p.dueDate || p.startDate <= p.dueDate, {
    message: 'Due date must be on or after the start date',
    path: ['dueDate'],
  })
export type Project = z.infer<typeof projectSchema>
export const projectInputSchema = z.object({
  workspaceId: id,
  name: name('Project name', 80),
  description: z.string().max(5_000).optional(),
  status: z.enum(PROJECT_STATUSES).optional(),
  priority: z.enum(PRIORITIES).optional(),
  startDate: isoDate.nullable().optional(),
  dueDate: isoDate.nullable().optional(),
  color: z.enum(PROJECT_COLORS).optional(),
})
export type ProjectInput = z.input<typeof projectInputSchema>

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

/** Persisted subset of the whiteboard scene. Engine-specific payloads stay opaque. */
export const drawingSceneSchema = z.object({
  elements: z.array(z.unknown()).default([]),
  appState: z.record(z.string(), z.unknown()).default({}),
  files: z.record(z.string(), z.unknown()).default({}),
})
export type DrawingScene = z.infer<typeof drawingSceneSchema>

export const drawingSchema = z.object({
  id,
  workspaceId: id,
  folderId: id.nullable().default(null),
  projectId: id.nullable().default(null),
  title: z.string().trim().max(200).default(''),
  scene: drawingSceneSchema.default({ elements: [], appState: {}, files: {} }),
  /** Small SVG preview (data URL) for cards. */
  thumbnail: z.string().nullable().default(null),
  ...timestamps,
})
export type Drawing = z.infer<typeof drawingSchema>
export const drawingInputSchema = drawingSchema.omit({ id: true, createdAt: true, updatedAt: true })
export type DrawingInput = z.input<typeof drawingInputSchema>

// ---------------------------------------------------------------------------
// Recently visited pages
// ---------------------------------------------------------------------------

export const ENTITY_TYPES = ['note', 'doc', 'task', 'project', 'drawing'] as const
export type EntityType = (typeof ENTITY_TYPES)[number]

export const recentVisitSchema = z.object({
  /** `${entityType}:${entityId}` — one row per entity. */
  id,
  workspaceId: id,
  entityType: z.enum(ENTITY_TYPES),
  entityId: id,
  visitedAt: z.number(),
})
export type RecentVisit = z.infer<typeof recentVisitSchema>

/** Fields every workspace-scoped entity carries. */
export interface WorkspaceEntity {
  id: string
  workspaceId: string
  createdAt: number
  updatedAt: number
}
