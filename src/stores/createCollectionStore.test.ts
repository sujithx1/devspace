import { describe, expect, it } from 'vitest'
import { ValidationError } from '@/data/errors'
import { createTestRepositories } from '@/test/repos'
import { createCollectionStore } from './createCollectionStore'

describe('collection store', () => {
  it('loads per workspace, applies optimistic updates and reverts failed ones', async () => {
    const { repos } = createTestRepositories()
    const ws = await repos.workspaces.create({ name: 'W' })
    const useTasks = createCollectionStore(repos.tasks)
    await useTasks.getState().load(ws.id)
    expect(useTasks.getState().status).toBe('ready')

    const task = await useTasks.getState().create({ workspaceId: ws.id, title: 'Write tests' })
    expect(useTasks.getState().items).toHaveLength(1)

    const pending = useTasks.getState().update(task.id, { status: 'in_progress' })
    expect(useTasks.getState().items[0].status).toBe('in_progress') // optimistic
    await pending

    await expect(useTasks.getState().update(task.id, { title: '' })).rejects.toBeInstanceOf(ValidationError)
    expect(useTasks.getState().items[0].title).toBe('Write tests') // reverted

    await useTasks.getState().remove(task.id)
    expect(useTasks.getState().items).toHaveLength(0)
    expect(await repos.tasks.get(task.id)).toBeUndefined()
  })
})
