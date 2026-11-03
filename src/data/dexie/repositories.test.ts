import { describe, expect, it } from 'vitest'
import { ValidationError } from '@/data/errors'
import { createTestRepositories } from '@/test/repos'

describe('Dexie repositories', () => {
  it('creates, lists and renames workspaces with validation', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: '  Personal  ' })
    expect(ws.name).toBe('Personal')
    expect(ws.icon).toBe('🚀')
    await expect(repos.workspaces.create({ name: '   ' })).rejects.toBeInstanceOf(ValidationError)

    const renamed = await repos.workspaces.update(ws.id, { name: 'Work' })
    expect(renamed.name).toBe('Work')
    expect(renamed.createdAt).toBe(ws.createdAt)
    expect(await repos.workspaces.list()).toHaveLength(1)
  })

  it('scopes collections to their workspace', async () => {
    const { repos } = createTestRepositories()
    const a = await repos.workspaces.create({ name: 'A' })
    const b = await repos.workspaces.create({ name: 'B' })
    await repos.notes.create({ workspaceId: a.id, title: 'In A' })
    await repos.notes.create({ workspaceId: b.id, title: 'In B' })
    const notes = await repos.notes.listByWorkspace(a.id)
    expect(notes.map((n) => n.title)).toEqual(['In A'])
  })

  it('applies defaults and ignores undefined fields in patches', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'W' })
    const note = await repos.notes.create({ workspaceId: ws.id, title: 'Draft', tags: ['idea'] })
    expect(note).toMatchObject({ folderId: null, projectId: null, plainText: '', pinned: false, content: null })

    const updated = await repos.notes.update(note.id, { title: undefined, pinned: true })
    expect(updated.title).toBe('Draft')
    expect(updated.pinned).toBe(true)
    expect(updated.updatedAt).toBeGreaterThanOrEqual(note.updatedAt)
  })

  it('tracks task completion time from status', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'W' })
    const task = await repos.tasks.create({ workspaceId: ws.id, title: 'Ship it' })
    expect(task.status).toBe('todo')
    expect(task.completedAt).toBeNull()

    const done = await repos.tasks.update(task.id, { status: 'completed' })
    expect(done.completedAt).toEqual(expect.any(Number))
    const stillDone = await repos.tasks.update(task.id, { title: 'Ship it now' })
    expect(stillDone.completedAt).toBe(done.completedAt)
    const reopened = await repos.tasks.update(task.id, { status: 'in_progress' })
    expect(reopened.completedAt).toBeNull()
  })

  it('rejects invalid task and project input', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'W' })
    await expect(repos.tasks.create({ workspaceId: ws.id, title: '' })).rejects.toThrow('Task title is required')
    await expect(repos.tasks.create({ workspaceId: ws.id, title: 'x', dueDate: '12/31/2026' })).rejects.toBeInstanceOf(ValidationError)
    await expect(
      repos.projects.create({ workspaceId: ws.id, name: 'P', startDate: '2026-05-01', dueDate: '2026-04-01' }),
    ).rejects.toThrow('Due date must be on or after the start date')
  })

  it('unlinks tasks, pages and drawings when a project is deleted', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'W' })
    const project = await repos.projects.create({ workspaceId: ws.id, name: 'API' })
    const task = await repos.tasks.create({ workspaceId: ws.id, title: 't', projectId: project.id })
    const doc = await repos.docs.create({ workspaceId: ws.id, title: 'd', projectId: project.id })
    const drawing = await repos.drawings.create({ workspaceId: ws.id, projectId: project.id })
    await repos.recents.touch(ws.id, 'project', project.id)

    await repos.projects.remove(project.id)
    expect((await repos.tasks.get(task.id))?.projectId).toBeNull()
    expect((await repos.docs.get(doc.id))?.projectId).toBeNull()
    expect((await repos.drawings.get(drawing.id))?.projectId).toBeNull()
    expect(await repos.recents.listByWorkspace(ws.id)).toHaveLength(0)
  })

  it('moves items out of a deleted folder', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'W' })
    const folder = await repos.folders.create({ workspaceId: ws.id, kind: 'note', name: 'Ideas' })
    const note = await repos.notes.create({ workspaceId: ws.id, folderId: folder.id })
    await repos.folders.remove(folder.id)
    expect(await repos.folders.get(folder.id)).toBeUndefined()
    expect((await repos.notes.get(note.id))?.folderId).toBeNull()
  })

  it('deletes everything in a workspace when the workspace is deleted', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'W' })
    const other = await repos.workspaces.create({ name: 'Other' })
    await repos.notes.create({ workspaceId: ws.id })
    await repos.tasks.create({ workspaceId: ws.id, title: 't' })
    await repos.notes.create({ workspaceId: other.id })

    await repos.workspaces.remove(ws.id)
    expect(await repos.workspaces.list()).toHaveLength(1)
    expect(await repos.notes.listByWorkspace(ws.id)).toHaveLength(0)
    expect(await repos.tasks.listByWorkspace(ws.id)).toHaveLength(0)
    expect(await repos.notes.listByWorkspace(other.id)).toHaveLength(1)
  })

  it('keeps recents most-recent-first with one row per entity', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'W' })
    await repos.recents.touch(ws.id, 'note', 'n1')
    await new Promise((r) => setTimeout(r, 2))
    await repos.recents.touch(ws.id, 'task', 't1')
    await new Promise((r) => setTimeout(r, 2))
    await repos.recents.touch(ws.id, 'note', 'n1')
    const recents = await repos.recents.listByWorkspace(ws.id)
    expect(recents.map((r) => r.id)).toEqual(['note:n1', 'task:t1'])
  })
})
