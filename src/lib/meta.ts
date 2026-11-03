import type { MemberRole, Priority, ProjectColor, ProjectStatus, TaskStatus } from '@/data'

/** Display metadata for enum values. Keeps labels and colours out of components. */

export const TASK_STATUS_META: Record<TaskStatus, { label: string; dot: string }> = {
  todo: { label: 'Todo', dot: 'bg-zinc-400' },
  in_progress: { label: 'In Progress', dot: 'bg-amber-500' },
  completed: { label: 'Completed', dot: 'bg-emerald-500' },
}

export const PRIORITY_META: Record<Priority, { label: string; className: string; rank: number }> = {
  low: { label: 'Low', className: 'text-zinc-500 bg-zinc-500/10', rank: 0 },
  medium: { label: 'Medium', className: 'text-sky-600 dark:text-sky-400 bg-sky-500/10', rank: 1 },
  high: { label: 'High', className: 'text-amber-600 dark:text-amber-400 bg-amber-500/10', rank: 2 },
  urgent: { label: 'Urgent', className: 'text-rose-600 dark:text-rose-400 bg-rose-500/10', rank: 3 },
}

export const PROJECT_STATUS_META: Record<ProjectStatus, { label: string; className: string }> = {
  planning: { label: 'Planning', className: 'text-violet-600 dark:text-violet-400 bg-violet-500/10' },
  active: { label: 'Active', className: 'text-emerald-600 dark:text-emerald-400 bg-emerald-500/10' },
  on_hold: { label: 'On hold', className: 'text-amber-600 dark:text-amber-400 bg-amber-500/10' },
  completed: { label: 'Completed', className: 'text-zinc-500 bg-zinc-500/10' },
}

export const PROJECT_COLOR_META: Record<ProjectColor, { swatch: string; soft: string; text: string }> = {
  indigo: { swatch: 'bg-indigo-500', soft: 'bg-indigo-500/12', text: 'text-indigo-600 dark:text-indigo-400' },
  emerald: { swatch: 'bg-emerald-500', soft: 'bg-emerald-500/12', text: 'text-emerald-600 dark:text-emerald-400' },
  amber: { swatch: 'bg-amber-500', soft: 'bg-amber-500/12', text: 'text-amber-600 dark:text-amber-400' },
  rose: { swatch: 'bg-rose-500', soft: 'bg-rose-500/12', text: 'text-rose-600 dark:text-rose-400' },
  sky: { swatch: 'bg-sky-500', soft: 'bg-sky-500/12', text: 'text-sky-600 dark:text-sky-400' },
  violet: { swatch: 'bg-violet-500', soft: 'bg-violet-500/12', text: 'text-violet-600 dark:text-violet-400' },
  zinc: { swatch: 'bg-zinc-500', soft: 'bg-zinc-500/12', text: 'text-zinc-600 dark:text-zinc-400' },
}

export const MEMBER_ROLE_META: Record<MemberRole, { label: string; description: string }> = {
  owner: { label: 'Owner', description: 'Manages the workspace and its members' },
  editor: { label: 'Editor', description: 'Creates and edits content' },
  viewer: { label: 'Viewer', description: 'Reads content only' },
}
