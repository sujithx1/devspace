import { describe, expect, it } from 'vitest'
import { createTestRepositories } from '@/test/repos'
import { exportWorkspace, importWorkspace, parseBackup } from './backup'

describe('workspace backup', () => {
  it('round-trips a workspace into a new one with remapped links', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'Source', icon: '🧪' })
    const folder = await repos.folders.create({ workspaceId: ws.id, kind: 'doc', name: 'Runbooks' })
    const project = await repos.projects.create({ workspaceId: ws.id, name: 'Infra' })
    await repos.tasks.create({ workspaceId: ws.id, title: 'Rotate keys', projectId: project.id, status: 'completed' })
    await repos.docs.create({ workspaceId: ws.id, title: 'Deploy', folderId: folder.id, projectId: project.id })

    const json = JSON.stringify(await exportWorkspace(repos, ws.id))
    const imported = await importWorkspace(repos, parseBackup(json))

    expect(imported.id).not.toBe(ws.id)
    expect(imported.name).toBe('Source (imported)')
    const [projects, docs, folders, tasks] = await Promise.all([
      repos.projects.listByWorkspace(imported.id),
      repos.docs.listByWorkspace(imported.id),
      repos.folders.listByWorkspace(imported.id),
      repos.tasks.listByWorkspace(imported.id),
    ])
    expect(projects).toHaveLength(1)
    expect(projects[0].id).not.toBe(project.id)
    expect(docs[0]).toMatchObject({ title: 'Deploy', projectId: projects[0].id, folderId: folders[0].id })
    expect(tasks[0]).toMatchObject({ title: 'Rotate keys', status: 'completed', projectId: projects[0].id })
    expect(tasks[0].completedAt).toEqual(expect.any(Number))
  })

  it('restores members and remaps task assignees', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'Team', type: 'group' })
    await repos.members.create({ workspaceId: ws.id, name: 'Owner', role: 'owner' })
    const lee = await repos.members.create({ workspaceId: ws.id, name: 'Lee', email: 'lee@x.dev' })
    await repos.tasks.create({ workspaceId: ws.id, title: 'Ship', assigneeId: lee.id })

    const imported = await importWorkspace(repos, parseBackup(JSON.stringify(await exportWorkspace(repos, ws.id))))
    expect(imported.type).toBe('group')
    const members = await repos.members.listByWorkspace(imported.id)
    const newLee = members.find((m) => m.name === 'Lee')!
    expect(members).toHaveLength(2)
    expect(newLee.id).not.toBe(lee.id)
    expect((await repos.tasks.listByWorkspace(imported.id))[0].assigneeId).toBe(newLee.id)
  })

  it('rejects files that are not DevSpace backups', () => {
    expect(() => parseBackup('not json')).toThrow('not valid JSON')
    expect(() => parseBackup('{"hello":1}')).toThrow('not a DevSpace workspace backup')
  })
})
