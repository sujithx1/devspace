import type { Project, ProjectStatus, Task } from '@/data'
import { PRIORITY_META } from '@/lib/meta'
import { daysUntil, todayISO } from '@/lib/utils'

export interface ProjectProgress {
  total: number
  completed: number
  percent: number
}

export function projectProgress(projectId: string, tasks: Task[]): ProjectProgress {
  const linked = tasks.filter((t) => t.projectId === projectId)
  const completed = linked.filter((t) => t.status === 'completed').length
  return { total: linked.length, completed, percent: linked.length ? Math.round((completed / linked.length) * 100) : 0 }
}

/** Human summary of a project's schedule, e.g. "Due in 5d" or "3d overdue". */
export function scheduleLabel(project: Pick<Project, 'dueDate' | 'status'>, today = todayISO()): { label: string; overdue: boolean } | null {
  if (!project.dueDate) return null
  if (project.status === 'completed') return { label: 'Completed', overdue: false }
  const days = daysUntil(project.dueDate, today)
  if (days < 0) return { label: `${-days}d overdue`, overdue: true }
  if (days === 0) return { label: 'Due today', overdue: false }
  return { label: `Due in ${days}d`, overdue: false }
}

export type ProjectSort = 'updated' | 'due' | 'priority' | 'name'

export function sortProjects(projects: Project[], sort: ProjectSort): Project[] {
  return [...projects].sort((a, b) => {
    switch (sort) {
      case 'name':
        return a.name.localeCompare(b.name)
      case 'priority':
        return PRIORITY_META[b.priority].rank - PRIORITY_META[a.priority].rank || b.updatedAt - a.updatedAt
      case 'due':
        if (a.dueDate === b.dueDate) return b.updatedAt - a.updatedAt
        return !a.dueDate ? 1 : !b.dueDate ? -1 : a.dueDate.localeCompare(b.dueDate)
      default:
        return b.updatedAt - a.updatedAt
    }
  })
}

export function filterProjects(projects: Project[], status: ProjectStatus | 'all', query: string): Project[] {
  const q = query.trim().toLowerCase()
  return projects.filter((p) => (status === 'all' || p.status === status) && (!q || `${p.name} ${p.description}`.toLowerCase().includes(q)))
}
