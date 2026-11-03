import { FolderKanban, Plus, Search } from 'lucide-react'
import { useMemo, useState } from 'react'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/Button'
import { EmptyState, ErrorState, Skeleton } from '@/components/ui/States'
import { PROJECT_STATUSES, type ProjectStatus } from '@/data'
import { PROJECT_STATUS_META } from '@/lib/meta'
import { cn } from '@/lib/utils'
import { useDocsStore, useNotesStore, useProjectsStore, useTasksStore } from '@/stores/collections'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { ProjectCard } from './ProjectCard'
import { filterProjects, projectProgress, sortProjects, type ProjectSort } from './projectLogic'

export function ProjectsPage() {
  const ws = useWorkspaceId()
  const { items, status, error, load } = useProjectsStore()
  const tasks = useTasksStore((s) => s.items)
  const notes = useNotesStore((s) => s.items)
  const docs = useDocsStore((s) => s.items)
  const openProject = useQuickCreateStore((s) => s.openProject)
  const canEdit = useCan('content.edit')
  const [tab, setTab] = useState<ProjectStatus | 'all'>('all')
  const [query, setQuery] = useState('')
  const [sort, setSort] = useState<ProjectSort>('updated')

  const visible = useMemo(() => sortProjects(filterProjects(items, tab, query), sort), [items, tab, query, sort])
  const counts = useMemo(() => {
    const c: Record<string, number> = { all: items.length }
    for (const s of PROJECT_STATUSES) c[s] = items.filter((p) => p.status === s).length
    return c
  }, [items])

  return (
    <>
      <PageHeader
        title="Projects"
        icon={<FolderKanban className="size-4" />}
        actions={
          canEdit && (
            <Button variant="primary" size="sm" onClick={() => openProject()}>
              <Plus className="size-3.5" /> New project
            </Button>
          )
        }
      />
      <div className="min-h-0 flex-1 overflow-y-auto p-4 md:p-6">
        {status === 'error' ? (
          <ErrorState message={error ?? 'Could not load projects'} onRetry={() => void load(ws)} />
        ) : status !== 'ready' ? (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <Skeleton key={i} className="h-56" />
            ))}
          </div>
        ) : items.length === 0 ? (
          <EmptyState
            icon={FolderKanban}
            title="No projects yet"
            description="Group tasks, notes, docs and diagrams around a goal, and track progress as tasks get done."
            action={
              canEdit && (
                <Button variant="primary" onClick={() => openProject()}>
                  <Plus className="size-4" /> Create a project
                </Button>
              )
            }
          />
        ) : (
          <div className="mx-auto max-w-6xl">
            <div className="mb-5 flex flex-wrap items-center gap-2">
              <div role="tablist" aria-label="Filter by status" className="flex flex-wrap gap-1">
                {(['all', ...PROJECT_STATUSES] as const).map((s) => (
                  <button
                    key={s}
                    role="tab"
                    type="button"
                    aria-selected={tab === s}
                    onClick={() => setTab(s)}
                    className={cn('h-7 rounded-md px-2.5 text-xs font-medium transition-colors', tab === s ? 'bg-fg text-canvas' : 'text-fg-muted hover:bg-surface-2 hover:text-fg')}
                  >
                    {s === 'all' ? 'All' : PROJECT_STATUS_META[s].label}
                    <span className="ml-1.5 opacity-60">{counts[s]}</span>
                  </button>
                ))}
              </div>
              <div className="flex-1" />
              <label className="relative">
                <span className="sr-only">Search projects</span>
                <Search className="pointer-events-none absolute top-1/2 left-2.5 size-3.5 -translate-y-1/2 text-fg-subtle" />
                <input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Search projects…"
                  className="h-8 w-52 rounded-md border border-line bg-surface pr-2 pl-8 text-sm outline-none placeholder:text-fg-subtle focus:border-accent"
                />
              </label>
              <select
                aria-label="Sort projects"
                value={sort}
                onChange={(e) => setSort(e.target.value as ProjectSort)}
                className="h-8 cursor-pointer rounded-md border border-line bg-surface px-2 text-xs text-fg-muted outline-none focus:border-accent"
              >
                <option value="updated">Recently updated</option>
                <option value="due">Due date</option>
                <option value="priority">Priority</option>
                <option value="name">Name</option>
              </select>
            </div>
            {visible.length === 0 ? (
              <p className="py-12 text-center text-sm text-fg-muted">No projects match.</p>
            ) : (
              <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
                {visible.map((p) => (
                  <ProjectCard
                    key={p.id}
                    project={p}
                    progress={projectProgress(p.id, tasks)}
                    noteCount={notes.filter((n) => n.projectId === p.id).length}
                    docCount={docs.filter((d) => d.projectId === p.id).length}
                  />
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </>
  )
}
