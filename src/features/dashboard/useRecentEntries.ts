import { useMemo } from 'react'
import type { EntityType } from '@/data'
import { untitled } from '@/lib/entities'
import { useDocsStore, useDrawingsStore, useNotesStore, useProjectsStore, useTasksStore } from '@/stores/collections'
import { useRecentsStore } from '@/stores/recentsStore'

export interface RecentEntry {
  type: EntityType
  id: string
  title: string
  visitedAt: number
}

/** Recently visited entities, resolved against live data (deleted items drop out). */
export function useRecentEntries(limit = 8): RecentEntry[] {
  const visits = useRecentsStore((s) => s.items)
  const notes = useNotesStore((s) => s.items)
  const docs = useDocsStore((s) => s.items)
  const tasks = useTasksStore((s) => s.items)
  const projects = useProjectsStore((s) => s.items)
  const drawings = useDrawingsStore((s) => s.items)

  return useMemo(() => {
    const titles: Record<EntityType, Map<string, string>> = {
      note: new Map(notes.map((n) => [n.id, untitled(n.title)])),
      doc: new Map(docs.map((d) => [d.id, untitled(d.title)])),
      task: new Map(tasks.map((t) => [t.id, t.title])),
      project: new Map(projects.map((p) => [p.id, p.name])),
      drawing: new Map(drawings.map((d) => [d.id, untitled(d.title)])),
    }
    const entries: RecentEntry[] = []
    for (const v of visits) {
      const title = titles[v.entityType].get(v.entityId)
      if (title !== undefined) entries.push({ type: v.entityType, id: v.entityId, title, visitedAt: v.visitedAt })
      if (entries.length >= limit) break
    }
    return entries
  }, [visits, notes, docs, tasks, projects, drawings, limit])
}

/** Records a visit to an entity for the "recent" lists. */
export function trackVisit(workspaceId: string, type: EntityType, id: string) {
  void useRecentsStore.getState().touch(workspaceId, type, id).catch(() => {
    // Recents are non-critical; ignore storage failures.
  })
}
