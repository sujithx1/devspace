import { z } from 'zod'
import { ValidationError } from './errors'
import { docSchema, drawingSchema, folderSchema, memberSchema, noteSchema, projectSchema, taskSchema, workspaceSchema, type Workspace } from './models'
import type { Repositories } from './repositories'

/**
 * Workspace backup/restore. Works purely through the repository interfaces, so
 * it keeps working when storage moves to a backend.
 */

export const BACKUP_VERSION = 1

const backupSchema = z.object({
  app: z.literal('devspace'),
  version: z.literal(BACKUP_VERSION),
  exportedAt: z.number(),
  workspace: workspaceSchema,
  // Older backups predate members.
  members: z.array(memberSchema).default([]),
  folders: z.array(folderSchema),
  projects: z.array(projectSchema),
  tasks: z.array(taskSchema),
  notes: z.array(noteSchema),
  docs: z.array(docSchema),
  drawings: z.array(drawingSchema),
})
export type WorkspaceBackup = z.infer<typeof backupSchema>

export async function exportWorkspace(repos: Repositories, workspaceId: string): Promise<WorkspaceBackup> {
  const workspace = await repos.workspaces.get(workspaceId)
  if (!workspace) throw new ValidationError('Workspace not found')
  const [members, folders, projects, tasks, notes, docs, drawings] = await Promise.all([
    repos.members.listByWorkspace(workspaceId),
    repos.folders.listByWorkspace(workspaceId),
    repos.projects.listByWorkspace(workspaceId),
    repos.tasks.listByWorkspace(workspaceId),
    repos.notes.listByWorkspace(workspaceId),
    repos.docs.listByWorkspace(workspaceId),
    repos.drawings.listByWorkspace(workspaceId),
  ])
  return { app: 'devspace', version: BACKUP_VERSION, exportedAt: Date.now(), workspace, members, folders, projects, tasks, notes, docs, drawings }
}

export function parseBackup(json: string): WorkspaceBackup {
  let data: unknown
  try {
    data = JSON.parse(json)
  } catch {
    throw new ValidationError('This file is not valid JSON')
  }
  const result = backupSchema.safeParse(data)
  if (!result.success) throw new ValidationError('This file is not a DevSpace workspace backup')
  return result.data
}

/** Restores a backup as a new workspace. All ids are regenerated; links are remapped. */
export async function importWorkspace(repos: Repositories, backup: WorkspaceBackup): Promise<Workspace> {
  const workspace = await repos.workspaces.create({
    name: `${backup.workspace.name} (imported)`.slice(0, 60),
    icon: backup.workspace.icon,
    type: backup.workspace.type,
  })
  const ws = workspace.id
  const folderIds = new Map<string, string>()
  const projectIds = new Map<string, string>()
  const memberIds = new Map<string, string>()
  const mapFolder = (id: string | null) => (id ? (folderIds.get(id) ?? null) : null)
  const mapProject = (id: string | null) => (id ? (projectIds.get(id) ?? null) : null)

  for (const m of backup.members) {
    memberIds.set(m.id, (await repos.members.create({ workspaceId: ws, name: m.name, email: m.email, role: m.role })).id)
  }
  for (const f of backup.folders) folderIds.set(f.id, (await repos.folders.create({ workspaceId: ws, kind: f.kind, name: f.name })).id)
  for (const p of backup.projects) {
    const { id, workspaceId: _w, createdAt: _c, updatedAt: _u, ...rest } = p
    projectIds.set(id, (await repos.projects.create({ ...rest, workspaceId: ws })).id)
  }
  for (const t of backup.tasks) {
    const { id: _id, workspaceId: _w, createdAt: _c, updatedAt: _u, completedAt: _d, ...rest } = t
    const assigneeId = t.assigneeId ? (memberIds.get(t.assigneeId) ?? null) : null
    await repos.tasks.create({ ...rest, workspaceId: ws, projectId: mapProject(t.projectId), assigneeId })
  }
  for (const [repo, pages] of [
    [repos.notes, backup.notes],
    [repos.docs, backup.docs],
  ] as const) {
    for (const page of pages) {
      const { id: _id, workspaceId: _w, createdAt: _c, updatedAt: _u, ...rest } = page
      await repo.create({ ...rest, workspaceId: ws, folderId: mapFolder(page.folderId), projectId: mapProject(page.projectId) })
    }
  }
  for (const d of backup.drawings) {
    const { id: _id, workspaceId: _w, createdAt: _c, updatedAt: _u, ...rest } = d
    await repos.drawings.create({ ...rest, workspaceId: ws, folderId: mapFolder(d.folderId), projectId: mapProject(d.projectId) })
  }
  return workspace
}
