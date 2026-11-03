import { CheckSquare, Columns3, List, Plus } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/Button'
import { EmptyState, ErrorState, Skeleton } from '@/components/ui/States'
import { cn } from '@/lib/utils'
import { useProjectsStore, useTasksStore } from '@/stores/collections'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { useMembers } from '@/features/members/useMembers'
import { KanbanBoard } from './KanbanBoard'
import { TaskFilterBar } from './TaskFilterBar'
import { TaskList } from './TaskList'
import { DEFAULT_TASK_FILTERS, filterTasks, isFilteringTasks, taskStats, type TaskFilters } from './taskLogic'

type View = 'board' | 'list'
const VIEW_KEY = 'devspace:taskView'

export function TasksPage() {
  const ws = useWorkspaceId()
  const { items, status, error, load } = useTasksStore()
  const projects = useProjectsStore((s) => s.items)
  const { members } = useMembers()
  const openTask = useQuickCreateStore((s) => s.openTask)
  const canEdit = useCan('content.edit')
  const [params, setParams] = useSearchParams()
  const [filters, setFilters] = useState<TaskFilters>(DEFAULT_TASK_FILTERS)
  const [view, setView] = useState<View>(() => {
    try {
      return localStorage.getItem(VIEW_KEY) === 'list' ? 'list' : 'board'
    } catch {
      return 'board'
    }
  })

  // Deep link: /tasks?task=<id> opens that task.
  const linkedTask = params.get('task')
  useEffect(() => {
    if (!linkedTask || status !== 'ready') return
    if (items.some((t) => t.id === linkedTask)) openTask({ taskId: linkedTask })
    setParams((p) => {
      p.delete('task')
      return p
    }, { replace: true })
  }, [linkedTask, status, items, openTask, setParams])

  const changeView = (v: View) => {
    setView(v)
    try {
      localStorage.setItem(VIEW_KEY, v)
    } catch {
      // View preference is optional.
    }
  }

  const visible = useMemo(() => filterTasks(items, filters), [items, filters])
  const stats = useMemo(() => taskStats(items), [items])

  return (
    <>
      <PageHeader
        title="Tasks"
        icon={<CheckSquare className="size-4" />}
        actions={
          <>
            <div role="radiogroup" aria-label="View" className="hidden items-center rounded-md border border-line p-0.5 sm:flex">
              {(
                [
                  ['board', Columns3, 'Board'],
                  ['list', List, 'List'],
                ] as const
              ).map(([v, Icon, label]) => (
                <button
                  key={v}
                  type="button"
                  role="radio"
                  aria-checked={view === v}
                  onClick={() => changeView(v)}
                  className={cn('flex h-6.5 items-center gap-1.5 rounded px-2 text-xs font-medium', view === v ? 'bg-surface-2 text-fg' : 'text-fg-muted hover:text-fg')}
                >
                  <Icon className="size-3.5" /> {label}
                </button>
              ))}
            </div>
            {canEdit && (
              <Button variant="primary" size="sm" onClick={() => openTask()}>
                <Plus className="size-3.5" /> New task
              </Button>
            )}
          </>
        }
      >
        {status === 'ready' && items.length > 0 && (
          <span className="ml-2 hidden text-xs text-fg-subtle lg:inline">
            {stats.completed}/{stats.total} completed{stats.overdue ? ` · ${stats.overdue} overdue` : ''}
          </span>
        )}
      </PageHeader>

      <div className="flex min-h-0 flex-1 flex-col gap-4 p-4 md:p-5">
        {status === 'error' ? (
          <ErrorState message={error ?? 'Could not load tasks'} onRetry={() => void load(ws)} />
        ) : status !== 'ready' ? (
          <div className="grid flex-1 grid-cols-1 gap-3 md:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <Skeleton key={i} className="h-64" />
            ))}
          </div>
        ) : items.length === 0 ? (
          <EmptyState
            icon={CheckSquare}
            title="No tasks yet"
            description="Track work across Todo, In Progress and Completed. Drag cards between columns as work moves."
            action={
              canEdit && (
                <Button variant="primary" onClick={() => openTask()}>
                  <Plus className="size-4" /> Create your first task
                </Button>
              )
            }
          />
        ) : (
          <>
            <TaskFilterBar filters={filters} onChange={setFilters} projects={projects} members={members} />
            {isFilteringTasks(filters) && visible.length === 0 ? (
              <p className="py-12 text-center text-sm text-fg-muted">No tasks match your filters.</p>
            ) : view === 'board' ? (
              <KanbanBoard tasks={visible} projects={projects} workspaceId={ws} className="hidden sm:grid" />
            ) : null}
            {/* The list view doubles as the mobile layout for the board. */}
            {visible.length > 0 && (
              <div className={cn('min-h-0 overflow-y-auto', view === 'board' && 'sm:hidden')}>
                <TaskList tasks={visible} projects={projects} />
              </div>
            )}
          </>
        )}
      </div>
    </>
  )
}
