import { describe, expect, it } from 'vitest'
import { repositories } from '@/data'
import { useWorkspaceStore } from './workspaceStore'

describe('workspace store', () => {
  it('creates a group workspace with its owner as the first member', async () => {
    const ws = await useWorkspaceStore.getState().create({ name: 'Platform team', type: 'group' }, { ownerName: 'Sujith' })
    const members = await repositories.members.listByWorkspace(ws.id)
    expect(members).toMatchObject([{ name: 'Sujith', role: 'owner' }])
    expect(useWorkspaceStore.getState().workspaces.some((w) => w.id === ws.id)).toBe(true)
  })

  it('creates private workspaces without members', async () => {
    const ws = await useWorkspaceStore.getState().create({ name: 'Notes' })
    expect(ws.type).toBe('private')
    expect(await repositories.members.listByWorkspace(ws.id)).toEqual([])
  })
})
