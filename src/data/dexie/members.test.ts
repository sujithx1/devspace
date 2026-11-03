import { describe, expect, it } from 'vitest'
import { ValidationError } from '@/data/errors'
import { createTestRepositories } from '@/test/repos'

async function groupWorkspace() {
  const { repos, db } = createTestRepositories()
  const ws = await repos.workspaces.create({ name: 'Team', type: 'group' })
  const owner = await repos.members.create({ workspaceId: ws.id, name: 'Sujith', role: 'owner' })
  return { repos, db, ws, owner }
}

describe('members', () => {
  it('defaults workspaces to private and accepts group', async () => {
    const { repos } = createTestRepositories()
    expect((await repos.workspaces.create({ name: 'Mine' })).type).toBe('private')
    expect((await repos.workspaces.create({ name: 'Team', type: 'group' })).type).toBe('group')
  })

  it('validates names, emails and keeps emails unique per workspace', async () => {
    const { repos, ws } = await groupWorkspace()
    await expect(repos.members.create({ workspaceId: ws.id, name: ' ' })).rejects.toThrow('Member name is required')
    await expect(repos.members.create({ workspaceId: ws.id, name: 'A', email: 'nope' })).rejects.toThrow('valid email')
    const priya = await repos.members.create({ workspaceId: ws.id, name: 'Priya', email: 'priya@acme.dev' })
    expect(priya.role).toBe('editor')
    await expect(repos.members.create({ workspaceId: ws.id, name: 'P2', email: 'PRIYA@acme.dev' })).rejects.toThrow('Priya already uses this email')
    const other = await repos.workspaces.create({ name: 'Other', type: 'group' })
    await expect(repos.members.create({ workspaceId: other.id, name: 'Priya', email: 'priya@acme.dev' })).resolves.toBeTruthy()
  })

  it('always keeps at least one owner', async () => {
    const { repos, ws, owner } = await groupWorkspace()
    await expect(repos.members.update(owner.id, { role: 'editor' })).rejects.toBeInstanceOf(ValidationError)
    await expect(repos.members.remove(owner.id)).rejects.toThrow('at least one owner')

    const second = await repos.members.create({ workspaceId: ws.id, name: 'Lee', role: 'owner' })
    await repos.members.update(owner.id, { role: 'viewer' })
    await expect(repos.members.remove(second.id)).rejects.toThrow('at least one owner')
  })

  it('unassigns tasks when a member is removed and deletes members with the workspace', async () => {
    const { repos, ws } = await groupWorkspace()
    const lee = await repos.members.create({ workspaceId: ws.id, name: 'Lee' })
    const task = await repos.tasks.create({ workspaceId: ws.id, title: 'Review PR', assigneeId: lee.id })
    expect(task.assigneeId).toBe(lee.id)

    await repos.members.remove(lee.id)
    expect((await repos.tasks.get(task.id))?.assigneeId).toBeNull()

    await repos.workspaces.remove(ws.id)
    expect(await repos.members.listByWorkspace(ws.id)).toEqual([])
  })
})
