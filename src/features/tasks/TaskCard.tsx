import { AlignLeft, ArrowRight, CalendarClock, Circle, Flag, Pencil, Trash2, UserMinus } from 'lucide-react'
import { forwardRef, type HTMLAttributes } from 'react'
import { PriorityBadge } from '@/components/ui/Badge'
import { PRIORITIES, TASK_STATUSES, type Member, type Project, type Task } from '@/data'
import { MemberAvatar } from '@/features/members/MemberAvatar'
import { PRIORITY_META, PROJECT_COLOR_META, TASK_STATUS_META } from '@/lib/meta'
import { cn } from '@/lib/utils'
import type { MenuItem } from '@/stores/menuStore'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { deleteTask, moveTask, updateTask } from './taskActions'
import { dueLabel, isOverdue } from './taskLogic'

/** Context menu for a task. `members` adds an "Assign to" section (group workspaces). */
export function taskMenu(task: Task, members: Member[] = []): MenuItem[] {
  const assign: MenuItem[] = members.length
    ? [
        { type: 'label', label: 'Assign to' },
        ...members.map<MenuItem>((m) => ({
          label: m.name,
          checked: task.assigneeId === m.id,
          onSelect: () => void updateTask(task.id, { assigneeId: m.id }),
        })),
        ...(task.assigneeId ? [{ label: 'Unassign', icon: UserMinus, onSelect: () => void updateTask(task.id, { assigneeId: null }) }] : []),
      ]
    : []
  return [
    { label: 'Edit task', icon: Pencil, onSelect: () => useQuickCreateStore.getState().openTask({ taskId: task.id }) },
    { type: 'label', label: 'Move to' },
    ...TASK_STATUSES.filter((s) => s !== task.status).map<MenuItem>((s) => ({
      label: TASK_STATUS_META[s].label,
      icon: ArrowRight,
      onSelect: () => void moveTask(task, s),
    })),
    { type: 'label', label: 'Priority' },
    ...PRIORITIES.map<MenuItem>((p) => ({
      label: PRIORITY_META[p].label,
      icon: Flag,
      checked: task.priority === p,
      onSelect: () => void updateTask(task.id, { priority: p }),
    })),
    ...assign,
    { type: 'separator' },
    { label: 'Delete task', icon: Trash2, danger: true, onSelect: () => void deleteTask(task) },
  ]
}

interface TaskCardProps extends HTMLAttributes<HTMLDivElement> {
  task: Task
  project?: Project
  assignee?: Member
  dragging?: boolean
  overlay?: boolean
}

export const TaskCard = forwardRef<HTMLDivElement, TaskCardProps>(function TaskCard({ task, project, assignee, dragging, overlay, className, ...props }, ref) {
  const overdue = isOverdue(task)
  const done = task.status === 'completed'
  return (
    <div
      ref={ref}
      className={cn(
        'group rounded-lg border border-line bg-surface p-3 text-left shadow-xs transition-[box-shadow,opacity,border-color] select-none',
        'hover:border-line-strong focus-visible:border-accent',
        dragging && 'opacity-40',
        overlay && 'rotate-[1.5deg] cursor-grabbing shadow-xl shadow-black/15',
        className,
      )}
      {...props}
    >
      <div className="flex items-start gap-2">
        <Circle className={cn('mt-0.5 size-3.5 shrink-0', done ? 'fill-emerald-500 text-emerald-500' : 'text-fg-subtle')} aria-hidden="true" />
        <p className={cn('flex-1 text-sm leading-snug font-medium break-words', done && 'text-fg-muted line-through')}>{task.title}</p>
        {assignee && <MemberAvatar member={assignee} size="xs" />}
      </div>
      <div className="mt-2.5 flex flex-wrap items-center gap-1.5 pl-5.5">
        <PriorityBadge priority={task.priority} />
        {task.dueDate && (
          <span className={cn('inline-flex h-5 items-center gap-1 rounded px-1.5 text-[11px] font-medium', overdue ? 'bg-danger-soft text-danger' : 'bg-surface-2 text-fg-muted')}>
            <CalendarClock className="size-3" />
            {dueLabel(task.dueDate)}
          </span>
        )}
        {project && (
          <span className={cn('inline-flex h-5 max-w-32 items-center gap-1 rounded px-1.5 text-[11px] font-medium', PROJECT_COLOR_META[project.color].soft, PROJECT_COLOR_META[project.color].text)}>
            <span className="truncate">{project.name}</span>
          </span>
        )}
        {task.description && <AlignLeft className="size-3 text-fg-subtle" aria-label="Has description" />}
      </div>
    </div>
  )
})
