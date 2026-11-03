import type { Priority, Task, TaskStatus } from '@/data'
import { TASK_STATUSES } from '@/data'
import { PRIORITY_META } from '@/lib/meta'
import { daysUntil, formatDate, todayISO } from '@/lib/utils'

export const ORDER_GAP = 1024

export type DueFilter = 'any' | 'overdue' | 'today' | 'week' | 'none'

/** `'any'`, `'unassigned'`, or a member id. */
export type AssigneeFilter = 'any' | 'unassigned' | (string & {})

export interface TaskFilters {
  query: string
  priority: Priority | null
  projectId: string | null
  due: DueFilter
  assignee: AssigneeFilter
}

export const DEFAULT_TASK_FILTERS: TaskFilters = { query: '', priority: null, projectId: null, due: 'any', assignee: 'any' }

export function isOverdue(task: Pick<Task, 'dueDate' | 'status'>, today = todayISO()) {
  return !!task.dueDate && task.status !== 'completed' && task.dueDate < today
}

export function filterTasks(tasks: Task[], f: TaskFilters, today = todayISO()): Task[] {
  const terms = f.query.toLowerCase().split(/\s+/).filter(Boolean)
  return tasks.filter((t) => {
    if (f.priority && t.priority !== f.priority) return false
    if (f.projectId && t.projectId !== f.projectId) return false
    if (f.assignee === 'unassigned' && t.assigneeId) return false
    if (f.assignee !== 'any' && f.assignee !== 'unassigned' && t.assigneeId !== f.assignee) return false
    if (f.due === 'none' && t.dueDate) return false
    if (f.due === 'overdue' && !isOverdue(t, today)) return false
    if (f.due === 'today' && t.dueDate !== today) return false
    if (f.due === 'week' && (!t.dueDate || daysUntil(t.dueDate, today) < 0 || daysUntil(t.dueDate, today) > 7)) return false
    if (terms.length) {
      const haystack = `${t.title} ${t.description}`.toLowerCase()
      if (!terms.every((term) => haystack.includes(term))) return false
    }
    return true
  })
}

export function isFilteringTasks(f: TaskFilters) {
  return !!f.query || !!f.priority || !!f.projectId || f.due !== 'any' || f.assignee !== 'any'
}

export function byOrder(a: Task, b: Task) {
  return a.order - b.order || a.createdAt - b.createdAt
}

export function groupByStatus(tasks: Task[]): Record<TaskStatus, Task[]> {
  const groups = Object.fromEntries(TASK_STATUSES.map((s) => [s, [] as Task[]])) as Record<TaskStatus, Task[]>
  for (const t of tasks) groups[t.status].push(t)
  for (const s of TASK_STATUSES) groups[s].sort(byOrder)
  return groups
}

/** Order value that places a task at the top of a column. */
export function topOrder(columnTasks: Task[]): number {
  return columnTasks.length ? Math.min(...columnTasks.map((t) => t.order)) - ORDER_GAP : 0
}

/**
 * Order value for inserting into `column` (sorted, excluding the moving task)
 * before the task with id `beforeId`, or at the end when `beforeId` is null.
 */
export function orderForInsert(column: Task[], beforeId: string | null): number {
  if (column.length === 0) return 0
  if (beforeId === null) return column[column.length - 1].order + ORDER_GAP
  const index = column.findIndex((t) => t.id === beforeId)
  if (index < 0) return column[column.length - 1].order + ORDER_GAP
  const next = column[index].order
  const prev = index > 0 ? column[index - 1].order : next - ORDER_GAP * 2
  return (prev + next) / 2
}

/** Sort for list views: open first, then priority, due date, and manual order. */
export function compareForList(a: Task, b: Task) {
  const done = Number(a.status === 'completed') - Number(b.status === 'completed')
  if (done) return done
  const pr = PRIORITY_META[b.priority].rank - PRIORITY_META[a.priority].rank
  if (pr) return pr
  if (a.dueDate !== b.dueDate) return !a.dueDate ? 1 : !b.dueDate ? -1 : a.dueDate.localeCompare(b.dueDate)
  return byOrder(a, b)
}

export interface TaskStats {
  total: number
  completed: number
  inProgress: number
  todo: number
  overdue: number
  completionRate: number
}

export function taskStats(tasks: Task[], today = todayISO()): TaskStats {
  const completed = tasks.filter((t) => t.status === 'completed').length
  return {
    total: tasks.length,
    completed,
    inProgress: tasks.filter((t) => t.status === 'in_progress').length,
    todo: tasks.filter((t) => t.status === 'todo').length,
    overdue: tasks.filter((t) => isOverdue(t, today)).length,
    completionRate: tasks.length ? Math.round((completed / tasks.length) * 100) : 0,
  }
}

export function dueLabel(dueDate: string, today = todayISO()): string {
  const days = daysUntil(dueDate, today)
  if (days === 0) return 'Today'
  if (days === 1) return 'Tomorrow'
  if (days === -1) return 'Yesterday'
  if (days < 0) return `${-days}d overdue`
  if (days < 7) return `In ${days}d`
  return formatDate(dueDate)
}
