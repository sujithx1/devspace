import { useDeferredValue, useMemo } from 'react'
import type { EntityType } from '@/data'
import { useDocsStore, useDrawingsStore, useNotesStore, useProjectsStore, useTasksStore } from '@/stores/collections'
import { search, type SearchResult } from './searchEngine'

/** Searches the active workspace's in-memory collections. */
export function useSearch(query: string, opts: { types?: EntityType[]; limit?: number } = {}): SearchResult[] {
  const notes = useNotesStore((s) => s.items)
  const docs = useDocsStore((s) => s.items)
  const tasks = useTasksStore((s) => s.items)
  const projects = useProjectsStore((s) => s.items)
  const drawings = useDrawingsStore((s) => s.items)
  const deferred = useDeferredValue(query)
  const typesKey = opts.types?.join(',') ?? ''

  return useMemo(
    () => search({ notes, docs, tasks, projects, drawings }, deferred, { types: typesKey ? (typesKey.split(',') as EntityType[]) : undefined, limit: opts.limit }),
    [notes, docs, tasks, projects, drawings, deferred, typesKey, opts.limit],
  )
}
