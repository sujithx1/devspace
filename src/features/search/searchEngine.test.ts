import { describe, expect, it } from 'vitest'
import type { Doc, Drawing, Note, Project, Task } from '@/data'
import { search, type SearchCorpus } from './searchEngine'

const base = { workspaceId: 'w', createdAt: 1, updatedAt: 1 }
const page = (id: string, title: string, plainText = ''): Note & Doc => ({ ...base, id, title, plainText, folderId: null, projectId: null, content: null, tags: [], pinned: false })

const corpus: SearchCorpus = {
  notes: [page('n1', 'Redis caching notes', 'TTL and eviction policies'), page('n2', 'Standup', 'discussed caching layer')],
  docs: [page('d1', 'Deploy runbook', 'kubectl rollout restart')],
  tasks: [{ ...base, id: 't1', title: 'Add cache headers', description: '', status: 'todo', priority: 'high', dueDate: null, order: 0, completedAt: null, projectId: null, assigneeId: null } satisfies Task],
  projects: [{ ...base, id: 'p1', name: 'Caching revamp', description: '', status: 'active', priority: 'medium', startDate: null, dueDate: null, color: 'indigo' } satisfies Project],
  drawings: [
    {
      ...base,
      id: 'w1',
      title: 'Architecture',
      folderId: null,
      projectId: null,
      thumbnail: null,
      scene: { elements: [{ type: 'text', text: 'Redis cluster' }, { type: 'text', text: 'gone', isDeleted: true }], appState: {}, files: {} },
    } satisfies Drawing,
  ],
}

describe('global search', () => {
  it('matches across every entity type, ranking title hits first', () => {
    const results = search(corpus, 'cach')
    expect(results.map((r) => r.id)).toEqual(expect.arrayContaining(['n1', 'n2', 't1', 'p1']))
    const titleHits = results.slice(0, 3).map((r) => r.id)
    expect(titleHits).not.toContain('n2')
  })

  it('requires every term to match and searches drawing text', () => {
    expect(search(corpus, 'redis cluster').map((r) => r.id)).toEqual(['w1'])
    expect(search(corpus, 'gone')).toEqual([])
    expect(search(corpus, 'kubectl').map((r) => r.type)).toEqual(['doc'])
  })

  it('filters by type and returns snippets', () => {
    const results = search(corpus, 'caching', { types: ['note'] })
    expect(results.every((r) => r.type === 'note')).toBe(true)
    expect(results.find((r) => r.id === 'n2')?.snippet).toContain('caching layer')
    expect(search(corpus, '   ')).toEqual([])
  })
})
