import { Search, X } from 'lucide-react'
import { PRIORITIES, type Member, type Priority, type Project } from '@/data'
import { PRIORITY_META } from '@/lib/meta'
import { cn } from '@/lib/utils'
import { DEFAULT_TASK_FILTERS, isFilteringTasks, type DueFilter, type TaskFilters } from './taskLogic'

const DUE_OPTIONS: { value: DueFilter; label: string }[] = [
  { value: 'any', label: 'Any due date' },
  { value: 'overdue', label: 'Overdue' },
  { value: 'today', label: 'Due today' },
  { value: 'week', label: 'Due in 7 days' },
  { value: 'none', label: 'No due date' },
]

const selectClass = 'h-8 cursor-pointer rounded-md border border-line bg-surface px-2 text-xs text-fg-muted outline-none focus:border-accent'

export function TaskFilterBar({
  filters,
  onChange,
  projects,
  hideProject,
  members = [],
}: {
  filters: TaskFilters
  onChange: (f: TaskFilters) => void
  projects: Project[]
  hideProject?: boolean
  /** Group workspace members; the assignee filter is shown only when provided. */
  members?: Member[]
}) {
  const set = <K extends keyof TaskFilters>(key: K, value: TaskFilters[K]) => onChange({ ...filters, [key]: value })
  return (
    <div className="flex flex-wrap items-center gap-2">
      <label className="relative min-w-48 flex-1 sm:max-w-72">
        <span className="sr-only">Search tasks</span>
        <Search className="pointer-events-none absolute top-1/2 left-2.5 size-3.5 -translate-y-1/2 text-fg-subtle" />
        <input
          value={filters.query}
          onChange={(e) => set('query', e.target.value)}
          placeholder="Search tasks…"
          className="h-8 w-full rounded-md border border-line bg-surface pr-2 pl-8 text-sm outline-none placeholder:text-fg-subtle focus:border-accent"
        />
      </label>
      <select aria-label="Filter by priority" value={filters.priority ?? ''} onChange={(e) => set('priority', (e.target.value || null) as Priority | null)} className={cn(selectClass, filters.priority && 'border-accent text-accent')}>
        <option value="">Any priority</option>
        {PRIORITIES.map((p) => (
          <option key={p} value={p}>
            {PRIORITY_META[p].label}
          </option>
        ))}
      </select>
      <select aria-label="Filter by due date" value={filters.due} onChange={(e) => set('due', e.target.value as DueFilter)} className={cn(selectClass, filters.due !== 'any' && 'border-accent text-accent')}>
        {DUE_OPTIONS.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
      {!hideProject && (
        <select aria-label="Filter by project" value={filters.projectId ?? ''} onChange={(e) => set('projectId', e.target.value || null)} className={cn(selectClass, filters.projectId && 'border-accent text-accent')}>
          <option value="">Any project</option>
          {projects.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
            </option>
          ))}
        </select>
      )}
      {members.length > 0 && (
        <select aria-label="Filter by assignee" value={filters.assignee} onChange={(e) => set('assignee', e.target.value)} className={cn(selectClass, filters.assignee !== 'any' && 'border-accent text-accent')}>
          <option value="any">Anyone</option>
          <option value="unassigned">Unassigned</option>
          {members.map((m) => (
            <option key={m.id} value={m.id}>
              {m.name}
            </option>
          ))}
        </select>
      )}
      {isFilteringTasks(filters) && (
        <button type="button" onClick={() => onChange(DEFAULT_TASK_FILTERS)} className="inline-flex h-8 items-center gap-1 rounded-md px-2 text-xs font-medium text-accent hover:bg-accent-soft">
          <X className="size-3" /> Clear
        </button>
      )}
    </div>
  )
}
