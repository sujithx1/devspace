import type { Table } from 'dexie'
import { ZodError, type ZodType } from 'zod'
import { createId } from '@/lib/id'
import { NotFoundError, ValidationError } from '../errors'
import {
  docSchema,
  drawingInputSchema,
  drawingSchema,
  folderInputSchema,
  folderSchema,
  memberInputSchema,
  memberSchema,
  noteSchema,
  pageInputSchema,
  projectInputSchema,
  projectSchema,
  taskInputSchema,
  taskSchema,
  workspaceInputSchema,
  workspaceSchema,
  type EntityType,
  type Member,
  type MemberInput,
  type RecentVisit,
  type Task,
  type WorkspaceEntity,
} from '../models'
import type {
  CollectionRepository,
  MemberRepository,
  RecentRepository,
  Repositories,
  WorkspaceRepository,
} from '../repositories'
import type { DevSpaceDB } from './db'

function validate<T>(schema: ZodType<T>, value: unknown): T {
  try {
    return schema.parse(value)
  } catch (error) {
    if (error instanceof ZodError) throw ValidationError.fromZod(error)
    throw error
  }
}

/** Drops keys whose value is `undefined` so partial patches never clobber stored fields. */
function definedOnly<T extends object>(patch: T): Partial<T> {
  return Object.fromEntries(Object.entries(patch).filter(([, v]) => v !== undefined)) as Partial<T>
}

const now = () => Date.now()

interface CollectionOptions<T extends WorkspaceEntity> {
  label: string
  table: Table<T, string>
  schema: ZodType<T>
  inputSchema: ZodType<unknown>
  /** Optional hook to derive fields whenever an entity is written. */
  beforeWrite?: (next: T, previous: T | undefined) => T
  /** Optional cascade run inside the delete transaction. */
  onRemove?: (id: string) => Promise<void>
  extraTables?: Table[]
}

function createCollectionRepository<T extends WorkspaceEntity, C, U = Partial<C>>(
  db: DevSpaceDB,
  { label, table, schema, inputSchema, beforeWrite, onRemove, extraTables = [] }: CollectionOptions<T>,
): CollectionRepository<T, C, U> {
  return {
    async listByWorkspace(workspaceId) {
      return table.where('workspaceId').equals(workspaceId).toArray()
    },
    async get(id) {
      return table.get(id)
    },
    async create(input) {
      const parsed = validate(inputSchema, input) as object
      const ts = now()
      let entity = validate(schema, { ...parsed, id: createId(), createdAt: ts, updatedAt: ts })
      if (beforeWrite) entity = beforeWrite(entity, undefined)
      await table.add(entity)
      return entity
    },
    async update(id, patch) {
      return db.transaction('rw', table, async () => {
        const existing = await table.get(id)
        if (!existing) throw new NotFoundError(label, id)
        let entity = validate(schema, {
          ...existing,
          ...definedOnly(patch as object),
          id: existing.id,
          workspaceId: existing.workspaceId,
          createdAt: existing.createdAt,
          updatedAt: now(),
        })
        if (beforeWrite) entity = beforeWrite(entity, existing)
        await table.put(entity)
        return entity
      })
    },
    async remove(id) {
      await db.transaction('rw', [table, db.recents, ...extraTables], async () => {
        await onRemove?.(id)
        await table.delete(id)
        await db.recents.where('entityId').equals(id).delete()
      })
    },
  }
}

function createWorkspaceRepository(db: DevSpaceDB): WorkspaceRepository {
  const scoped = [db.members, db.folders, db.notes, db.docs, db.tasks, db.projects, db.drawings, db.recents]
  return {
    async list() {
      return (await db.workspaces.toArray()).sort((a, b) => a.createdAt - b.createdAt)
    },
    async get(id) {
      return db.workspaces.get(id)
    },
    async create(input) {
      const parsed = validate(workspaceInputSchema, input)
      const ts = now()
      const workspace = validate(workspaceSchema, { ...parsed, id: createId(), createdAt: ts, updatedAt: ts })
      await db.workspaces.add(workspace)
      return workspace
    },
    async update(id, patch) {
      return db.transaction('rw', db.workspaces, async () => {
        const existing = await db.workspaces.get(id)
        if (!existing) throw new NotFoundError('Workspace', id)
        const workspace = validate(workspaceSchema, { ...existing, ...definedOnly(patch), updatedAt: now() })
        await db.workspaces.put(workspace)
        return workspace
      })
    },
    async remove(id) {
      await db.transaction('rw', [db.workspaces, ...scoped], async () => {
        for (const table of scoped) await table.where('workspaceId').equals(id).delete()
        await db.workspaces.delete(id)
      })
    },
  }
}

function createRecentRepository(db: DevSpaceDB): RecentRepository {
  return {
    async listByWorkspace(workspaceId, limit = 12) {
      return db.recents
        .where('[workspaceId+visitedAt]')
        .between([workspaceId, -Infinity], [workspaceId, Infinity])
        .reverse()
        .limit(limit)
        .toArray()
    },
    async touch(workspaceId, entityType, entityId) {
      const visit: RecentVisit = {
        id: `${entityType}:${entityId}`,
        workspaceId,
        entityType,
        entityId,
        visitedAt: now(),
      }
      await db.recents.put(visit)
      return visit
    },
    async forget(entityType: EntityType, entityId: string) {
      await db.recents.delete(`${entityType}:${entityId}`)
    },
  }
}

/**
 * Members enforce workspace-level rules that a backend would also own:
 * at least one owner, unique emails, and unassigning tasks when someone leaves.
 */
function createMemberRepository(db: DevSpaceDB): MemberRepository {
  const base = createCollectionRepository<Member, MemberInput>(db, {
    label: 'Member',
    table: db.members,
    schema: memberSchema,
    inputSchema: memberInputSchema,
    onRemove: async (id) => {
      await db.tasks.where('assigneeId').equals(id).modify({ assigneeId: null })
    },
    extraTables: [db.tasks],
  })

  const ownerCount = (workspaceId: string) =>
    db.members.where('workspaceId').equals(workspaceId).filter((m) => m.role === 'owner').count()

  const assertUniqueEmail = async (workspaceId: string, email: string | undefined, exceptId?: string) => {
    const normalized = email?.trim().toLowerCase()
    if (!normalized) return
    const clash = await db.members
      .where('workspaceId')
      .equals(workspaceId)
      .filter((m) => m.id !== exceptId && m.email.toLowerCase() === normalized)
      .first()
    if (clash) throw new ValidationError(`${clash.name} already uses this email`, { email: `${clash.name} already uses this email` })
  }

  const getExisting = async (id: string) => {
    const existing = await db.members.get(id)
    if (!existing) throw new NotFoundError('Member', id)
    return existing
  }

  const lastOwnerError = () =>
    new ValidationError('A group workspace needs at least one owner', { role: 'A group workspace needs at least one owner' })

  return {
    ...base,
    async create(input) {
      await assertUniqueEmail(input.workspaceId, input.email)
      return base.create(input)
    },
    async update(id, patch) {
      const existing = await getExisting(id)
      if (existing.role === 'owner' && patch.role && patch.role !== 'owner' && (await ownerCount(existing.workspaceId)) <= 1) {
        throw lastOwnerError()
      }
      await assertUniqueEmail(existing.workspaceId, patch.email, id)
      return base.update(id, patch)
    },
    async remove(id) {
      const existing = await getExisting(id)
      if (existing.role === 'owner' && (await ownerCount(existing.workspaceId)) <= 1) throw lastOwnerError()
      return base.remove(id)
    },
  }
}

/** Keeps `completedAt` consistent with `status`. */
function trackCompletion(next: Task, previous: Task | undefined): Task {
  if (next.status === 'completed') {
    return { ...next, completedAt: previous?.status === 'completed' ? previous.completedAt ?? now() : now() }
  }
  return { ...next, completedAt: null }
}

export function createDexieRepositories(db: DevSpaceDB): Repositories {
  const unlinkFolder = async (folderId: string) => {
    for (const table of [db.notes, db.docs, db.drawings] as Table<{ folderId: string | null }, string>[]) {
      await table.where('folderId').equals(folderId).modify({ folderId: null })
    }
  }
  const unlinkProject = async (projectId: string) => {
    for (const table of [db.tasks, db.notes, db.docs, db.drawings] as Table<{ projectId: string | null }, string>[]) {
      await table.where('projectId').equals(projectId).modify({ projectId: null })
    }
  }

  return {
    workspaces: createWorkspaceRepository(db),
    members: createMemberRepository(db),
    recents: createRecentRepository(db),
    folders: createCollectionRepository(db, {
      label: 'Folder',
      table: db.folders,
      schema: folderSchema,
      inputSchema: folderInputSchema,
      onRemove: unlinkFolder,
      extraTables: [db.notes, db.docs, db.drawings],
    }),
    notes: createCollectionRepository(db, {
      label: 'Note',
      table: db.notes,
      schema: noteSchema,
      inputSchema: pageInputSchema,
    }),
    docs: createCollectionRepository(db, {
      label: 'Document',
      table: db.docs,
      schema: docSchema,
      inputSchema: pageInputSchema,
    }),
    tasks: createCollectionRepository(db, {
      label: 'Task',
      table: db.tasks,
      schema: taskSchema,
      inputSchema: taskInputSchema,
      beforeWrite: trackCompletion,
    }),
    projects: createCollectionRepository(db, {
      label: 'Project',
      table: db.projects,
      schema: projectSchema,
      inputSchema: projectInputSchema,
      onRemove: unlinkProject,
      extraTables: [db.tasks, db.notes, db.docs, db.drawings],
    }),
    drawings: createCollectionRepository(db, {
      label: 'Drawing',
      table: db.drawings,
      schema: drawingSchema,
      inputSchema: drawingInputSchema,
    }),
  }
}
