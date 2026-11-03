import Dexie from 'dexie'
import { describe, expect, it } from 'vitest'
import { DevSpaceDB } from './db'
import { createDexieRepositories } from './repositories'

describe('database migration v1 → v2', () => {
  it('marks existing workspaces private and existing tasks unassigned', async () => {
    const name = `devspace-migration-${Date.now()}`
    const v1 = new Dexie(name)
    v1.version(1).stores({
      workspaces: 'id, updatedAt',
      folders: 'id, workspaceId, [workspaceId+kind]',
      notes: 'id, workspaceId, folderId, projectId, updatedAt',
      docs: 'id, workspaceId, folderId, projectId, updatedAt',
      tasks: 'id, workspaceId, projectId, status',
      projects: 'id, workspaceId',
      drawings: 'id, workspaceId, folderId, projectId, updatedAt',
      recents: 'id, workspaceId, entityId, [workspaceId+visitedAt]',
    })
    await v1.table('workspaces').add({ id: 'w1', name: 'Old', icon: '🚀', createdAt: 1, updatedAt: 1 })
    await v1.table('tasks').add({
      id: 't1', workspaceId: 'w1', projectId: null, title: 'Legacy', description: '', status: 'todo',
      priority: 'medium', dueDate: null, order: 0, completedAt: null, createdAt: 1, updatedAt: 1,
    })
    v1.close()

    const repos = createDexieRepositories(new DevSpaceDB(name))
    expect((await repos.workspaces.get('w1'))?.type).toBe('private')
    expect((await repos.tasks.get('t1'))?.assigneeId).toBeNull()
    expect(await repos.members.listByWorkspace('w1')).toEqual([])
  })
})
