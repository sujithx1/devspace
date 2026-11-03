import type { Doc, Drawing, EntityType, Note, Project, Task } from '@/data'
import { TASK_STATUS_META } from '@/lib/meta'
import { excerpt } from '@/lib/utils'
import { untitled } from '@/lib/entities'

export interface SearchCorpus {
  notes: Note[]
  docs: Doc[]
  tasks: Task[]
  projects: Project[]
  drawings: Drawing[]
}

export interface SearchResult {
  type: EntityType
  id: string
  title: string
  snippet: string
  /** Short context, e.g. task status. */
  meta?: string
  updatedAt: number
  score: number
}

interface Searchable {
  type: EntityType
  id: string
  title: string
  body: string
  meta?: string
  updatedAt: number
}

function toSearchables(corpus: SearchCorpus): Searchable[] {
  const drawingText = (d: Drawing) =>
    (d.scene.elements as { type?: string; text?: string; isDeleted?: boolean }[])
      .filter((el) => el.type === 'text' && !el.isDeleted && el.text)
      .map((el) => el.text)
      .join(' ')
  return [
    ...corpus.notes.map((n) => ({ type: 'note' as const, id: n.id, title: untitled(n.title), body: `${n.plainText} ${n.tags.join(' ')}`, updatedAt: n.updatedAt })),
    ...corpus.docs.map((d) => ({ type: 'doc' as const, id: d.id, title: untitled(d.title), body: `${d.plainText} ${d.tags.join(' ')}`, updatedAt: d.updatedAt })),
    ...corpus.tasks.map((t) => ({ type: 'task' as const, id: t.id, title: t.title, body: t.description, meta: TASK_STATUS_META[t.status].label, updatedAt: t.updatedAt })),
    ...corpus.projects.map((p) => ({ type: 'project' as const, id: p.id, title: p.name, body: p.description, updatedAt: p.updatedAt })),
    ...corpus.drawings.map((d) => ({ type: 'drawing' as const, id: d.id, title: untitled(d.title), body: drawingText(d), updatedAt: d.updatedAt })),
  ]
}

/**
 * Ranks entities against `query`. Every whitespace-separated term must appear
 * in the title or body; title hits and prefix matches score higher.
 */
export function search(corpus: SearchCorpus, query: string, opts: { types?: EntityType[]; limit?: number } = {}): SearchResult[] {
  const terms = query.toLowerCase().split(/\s+/).filter(Boolean)
  if (terms.length === 0) return []
  const allowed = opts.types && opts.types.length > 0 ? new Set(opts.types) : null

  const results: SearchResult[] = []
  for (const item of toSearchables(corpus)) {
    if (allowed && !allowed.has(item.type)) continue
    const title = item.title.toLowerCase()
    const body = item.body.toLowerCase()
    let score = 0
    let matchedAll = true
    for (const term of terms) {
      const inTitle = title.indexOf(term)
      const inBody = body.indexOf(term)
      if (inTitle < 0 && inBody < 0) {
        matchedAll = false
        break
      }
      if (inTitle >= 0) score += inTitle === 0 ? 12 : title[inTitle - 1] === ' ' ? 9 : 6
      if (inBody >= 0) score += 2
    }
    if (!matchedAll) continue
    if (title === query.toLowerCase().trim()) score += 20
    const firstBodyTerm = terms.find((t) => body.includes(t)) ?? ''
    results.push({
      type: item.type,
      id: item.id,
      title: item.title,
      snippet: firstBodyTerm ? excerpt(item.body, firstBodyTerm) : excerpt(item.body, ''),
      meta: item.meta,
      updatedAt: item.updatedAt,
      score,
    })
  }
  results.sort((a, b) => b.score - a.score || b.updatedAt - a.updatedAt)
  return opts.limit ? results.slice(0, opts.limit) : results
}
