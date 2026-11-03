import { describe, expect, it } from 'vitest'
import type { Page } from '@/data'
import { DEFAULT_PAGE_FILTERS, collectTags, filterPages } from './filterPages'

const page = (over: Partial<Page>): Page => ({
  id: Math.random().toString(36),
  workspaceId: 'w',
  folderId: null,
  projectId: null,
  title: '',
  content: null,
  plainText: '',
  tags: [],
  pinned: false,
  createdAt: 0,
  updatedAt: 0,
  ...over,
})

describe('filterPages', () => {
  const pages = [
    page({ title: 'Alpha', updatedAt: 1, tags: ['go'] }),
    page({ title: 'Beta', updatedAt: 3, plainText: 'golang generics' }),
    page({ title: 'Gamma', updatedAt: 2, pinned: true, projectId: 'p' }),
  ]

  it('sorts pinned first, then by last edit', () => {
    expect(filterPages(pages, DEFAULT_PAGE_FILTERS).map((p) => p.title)).toEqual(['Gamma', 'Beta', 'Alpha'])
  })

  it('filters by text, tag, project and pinned', () => {
    const titles = (f: Partial<typeof DEFAULT_PAGE_FILTERS>) => filterPages(pages, { ...DEFAULT_PAGE_FILTERS, ...f }).map((p) => p.title)
    expect(titles({ query: 'go' })).toEqual(['Beta', 'Alpha'])
    expect(titles({ tag: 'go' })).toEqual(['Alpha'])
    expect(titles({ projectId: 'p' })).toEqual(['Gamma'])
    expect(titles({ pinnedOnly: true })).toEqual(['Gamma'])
    expect(titles({ sort: 'title' })).toEqual(['Gamma', 'Alpha', 'Beta'])
  })

  it('collects unique sorted tags', () => {
    expect(collectTags([...pages, page({ tags: ['ai', 'go'] })])).toEqual(['ai', 'go'])
  })
})
