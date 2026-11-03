import { CalendarClock, MoreHorizontal } from 'lucide-react'
import { useMemo } from 'react'
import { PriorityBadge } from '@/components/ui/Badge'
import type { Project, Task } from '@/data'
import { MemberAvatar } from '@/features/members/MemberAvatar'
import { useMembers } from '@/features/members/useMembers'
import { PROJECT_COLOR_META, TASK_STATUS_META } from '@/lib/meta'
import { cn } from '@/lib/utils'
import { openContextMenu, openDropdownMenu } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { updateTask } from './taskActions'
import { taskMenu } from './TaskCard'
import { compareForList, dueLabel, isOverdue } from './taskLogic'

/** Dense list view of tasks with inline completion toggles. */
export function TaskList({ tasks, projects }: { tasks: Task[]; projects: Project[] }) {
  const sorted = useMemo(() => [...tasks].sort(compareForList), [tasks])
  const projectMap = useMemo(() => new Map(projects.map((p) => [p.id, p])), [projects])
  const openTask = useQuickCreateStore((s) => s.openTask)
  const { members, byId: memberMap } = useMembers()
  const canEdit = useCan('content.edit')

  return (
    <ul className="divide-y divide-line overflow-hidden rounded-xl border border-line bg-surface">
      {sorted.map((task) => {
        const project = task.projectId ? projectMap.get(task.projectId) : undefined
        const assignee = task.assigneeId ? memberMap.get(task.assigneeId) : undefined
        const done = task.status === 'completed'
        return (
          <li key={task.id} onContextMenu={(e) => canEdit && openContextMenu(e, taskMenu(task, members))} className="group flex items-center gap-3 px-3 py-2.5 hover:bg-surface-2/60">
            <input
              type="checkbox"
              checked={done}
              disabled={!canEdit}
              aria-label={done ? `Mark “${task.title}” as not completed` : `Mark “${task.title}” as completed`}
              onChange={() => void updateTask(task.id, { status: done ? 'todo' : 'completed' })}
              className="size-4 shrink-0 cursor-pointer accent-[var(--ds-accent)] disabled:cursor-default"
            />
            <button type="button" onClick={() => openTask({ taskId: task.id })} className="min-w-0 flex-1 text-left">
              <span className={cn('block truncate text-sm', done && 'text-fg-muted line-through')}>{task.title}</span>
            </button>
            <span className="hidden items-center gap-1.5 text-xs text-fg-muted sm:flex">
              <span className={cn('size-1.5 rounded-full', TASK_STATUS_META[task.status].dot)} />
              {TASK_STATUS_META[task.status].label}
            </span>
            {project && (
              <span className={cn('hidden max-w-36 truncate rounded px-1.5 py-0.5 text-[11px] font-medium md:inline', PROJECT_COLOR_META[project.color].soft, PROJECT_COLOR_META[project.color].text)}>
                {project.name}
              </span>
            )}
            {task.dueDate && (
              <span className={cn('flex items-center gap-1 text-xs', isOverdue(task) ? 'text-danger' : 'text-fg-muted')}>
                <CalendarClock className="size-3" />
                {dueLabel(task.dueDate)}
              </span>
            )}
            <PriorityBadge priority={task.priority} />
            {assignee && <MemberAvatar member={assignee} size="xs" />}
            {canEdit && (
              <button
                type="button"
                aria-label={`Actions for ${task.title}`}
                aria-haspopup="menu"
                onClick={(e) => openDropdownMenu(e, taskMenu(task, members))}
                className="rounded p-1 text-fg-subtle opacity-0 group-hover:opacity-100 hover:bg-line hover:text-fg focus:opacity-100"
              >
                <MoreHorizontal className="size-4" />
              </button>
            )}
          </li>
        )
      })}
    </ul>
  )
}
