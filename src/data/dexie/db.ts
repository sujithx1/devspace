import Dexie, { type Table } from 'dexie'
import type { Doc, Drawing, Folder, Member, Note, Project, RecentVisit, Task, Workspace } from '../models'

export class DevSpaceDB extends Dexie {
  workspaces!: Table<Workspace, string>
  members!: Table<Member, string>
  folders!: Table<Folder, string>
  notes!: Table<Note, string>
  docs!: Table<Doc, string>
  tasks!: Table<Task, string>
  projects!: Table<Project, string>
  drawings!: Table<Drawing, string>
  recents!: Table<RecentVisit, string>

  constructor(name = 'devspace') {
    super(name)
    this.version(1).stores({
      workspaces: 'id, updatedAt',
      folders: 'id, workspaceId, [workspaceId+kind]',
      notes: 'id, workspaceId, folderId, projectId, updatedAt',
      docs: 'id, workspaceId, folderId, projectId, updatedAt',
      tasks: 'id, workspaceId, projectId, status',
      projects: 'id, workspaceId',
      drawings: 'id, workspaceId, folderId, projectId, updatedAt',
      recents: 'id, workspaceId, entityId, [workspaceId+visitedAt]',
    })
    // v2: workspace types, group members and task assignees.
    this.version(2)
      .stores({
        members: 'id, workspaceId',
        tasks: 'id, workspaceId, projectId, status, assigneeId',
      })
      .upgrade(async (tx) => {
        await tx.table('workspaces').toCollection().modify((w: Partial<Workspace>) => {
          w.type ??= 'private'
        })
        await tx.table('tasks').toCollection().modify((t: Partial<Task>) => {
          t.assigneeId ??= null
        })
      })
  }
}
