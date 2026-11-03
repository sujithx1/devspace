import { beforeAll, describe, expect, it } from 'vitest'
import { repositories, type Member, type Workspace } from '@/data'
import { useMembersStore, useNotesStore, useTasksStore } from './collections'
import { PermissionError } from './guard'
import { canNow, roleCan, useActingStore } from './permissions'
import { useWorkspaceStore } from './workspaceStore'

let ws: Workspace
let owner: Member
let editor: Member
let viewer: Member

beforeAll(async () => {
  await useWorkspaceStore.getState().init()
  ws = await useWorkspaceStore.getState().create({ name: 'Team', type: 'group' }, { ownerName: 'Olivia' })
  ;[owner] = await repositories.members.listByWorkspace(ws.id)
  editor = await repositories.members.create({ workspaceId: ws.id, name: 'Ed', role: 'editor' })
  viewer = await repositories.members.create({ workspaceId: ws.id, name: 'Vi', role: 'viewer' })
  await useWorkspaceStore.getState().activate(ws.id)
})

const actAs = (m: Member) => useActingStore.getState().actAs(ws.id, m.id)

describe('role permissions', () => {
  it('maps roles to permissions', () => {
    expect(roleCan('owner', 'workspace.manage')).toBe(true)
    expect(roleCan('editor', 'content.edit')).toBe(true)
    expect(roleCan('editor', 'members.manage')).toBe(false)
    expect(roleCan('viewer', 'content.edit')).toBe(false)
  })

  it('defaults to the first owner when nobody has been picked', () => {
    useActingStore.setState({ actingAs: {} })
    expect(canNow('workspace.manage')).toBe(true)
    expect(owner.role).toBe('owner')
  })

  it('blocks every write for a viewer', async () => {
    actAs(viewer)
    expect(canNow('content.edit')).toBe(false)
    await expect(useNotesStore.getState().create({ workspaceId: ws.id, title: 'x' })).rejects.toBeInstanceOf(PermissionError)
    await expect(useTasksStore.getState().create({ workspaceId: ws.id, title: 'x' })).rejects.toThrow('Viewers can only read')
    await expect(useMembersStore.getState().create({ workspaceId: ws.id, name: 'New' })).rejects.toBeInstanceOf(PermissionError)
    await expect(useWorkspaceStore.getState().update(ws.id, { name: 'Renamed' })).rejects.toBeInstanceOf(PermissionError)
    expect(await repositories.notes.listByWorkspace(ws.id)).toEqual([])
  })

  it('lets editors change content but not members or the workspace', async () => {
    actAs(editor)
    const note = await useNotesStore.getState().create({ workspaceId: ws.id, title: 'Spec' })
    await useNotesStore.getState().update(note.id, { title: 'Spec v2' })
    expect((await repositories.notes.get(note.id))?.title).toBe('Spec v2')
    await expect(useMembersStore.getState().update(viewer.id, { role: 'editor' })).rejects.toThrow('Only owners can manage members')
    await expect(useWorkspaceStore.getState().update(ws.id, { name: 'Renamed' })).rejects.toThrow('Only owners can change workspace settings')
  })

  it('lets owners do everything', async () => {
    actAs(owner)
    await useMembersStore.getState().update(viewer.id, { role: 'editor' })
    expect((await useWorkspaceStore.getState().update(ws.id, { name: 'Renamed' })).name).toBe('Renamed')
  })

  it('gives full access in private workspaces', async () => {
    const personal = await useWorkspaceStore.getState().create({ name: 'Personal' })
    await useWorkspaceStore.getState().activate(personal.id)
    expect(canNow('workspace.manage')).toBe(true)
    await expect(useNotesStore.getState().create({ workspaceId: personal.id, title: 'Mine' })).resolves.toBeTruthy()
  })
})
