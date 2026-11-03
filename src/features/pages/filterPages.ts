import type { Page } from '@/data'

export type PageSort = 'updated' | 'created' | 'title'

export interface PageFilters {
  query: string
  pinnedOnly: boolean
  projectId: string | null
  tag: string | null
  sort: PageSort
}

export const DEFAULT_PAGE_FILTERS: PageFilters = { query: '', pinnedOnly: false, projectId: null, tag: null, sort: 'updated' }

export function filterPages(pages: Page[], f: PageFilters): Page[] {
  const terms = f.query.toLowerCase().split(/\s+/).filter(Boolean)
  const result = pages.filter((p) => {
    if (f.pinnedOnly && !p.pinned) return false
    if (f.projectId && p.projectId !== f.projectId) return false
    if (f.tag && !p.tags.includes(f.tag)) return false
    if (terms.length) {
      const haystack = `${p.title} ${p.plainText} ${p.tags.join(' ')}`.toLowerCase()
      if (!terms.every((t) => haystack.includes(t))) return false
    }
    return true
  })
  return result.sort((a, b) => {
    if (a.pinned !== b.pinned) return a.pinned ? -1 : 1
    if (f.sort === 'title') return (a.title || 'Untitled').localeCompare(b.title || 'Untitled')
    if (f.sort === 'created') return b.createdAt - a.createdAt
    return b.updatedAt - a.updatedAt
  })
}

export function collectTags(pages: Page[]): string[] {
  return [...new Set(pages.flatMap((p) => p.tags))].sort()
}

export function isFiltering(f: PageFilters) {
  return !!f.query || f.pinnedOnly || !!f.projectId || !!f.tag
}
