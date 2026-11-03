import {
  DndContext,
  DragOverlay,
  KeyboardSensor,
  PointerSensor,
  pointerWithin,
  rectIntersection,
  useDraggable,
  useDroppable,
  useSensor,
  useSensors,
  type Announcements,
  type CollisionDetection,
  type DragEndEvent,
  type DragStartEvent,
} from '@dnd-kit/core'
import { Plus } from 'lucide-react'
import { useMemo, useState, type FormEvent } from 'react'
import { TASK_STATUSES, ValidationError, type Member, type Project, type Task, type TaskStatus } from '@/data'
import { useMembers } from '@/features/members/useMembers'
import { TASK_STATUS_META } from '@/lib/meta'
import { cn } from '@/lib/utils'
import { openContextMenu } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { toast } from '@/stores/toastStore'
import { createTask, updateTask } from './taskActions'
import { TaskCard, taskMenu } from './TaskCard'
import { groupByStatus, orderForInsert } from './taskLogic'

interface Props {
  tasks: Task[]
  projects: Project[]
  workspaceId: string
  /** New tasks created from the board are linked to this project. */
  projectId?: string | null
  className?: string
}

/** Prefer card targets (for precise insertion), then columns. Falls back to rects for keyboard drags. */
const collisionDetection: CollisionDetection = (args) => {
  const hits = pointerWithin(args)
  const collisions = hits.length ? hits : rectIntersection(args)
  const cards = collisions.filter((c) => String(c.id).startsWith('card:'))
  return cards.length ? cards : collisions
}

export function KanbanBoard({ tasks, projects, workspaceId, projectId = null, className }: Props) {
  const columns = useMemo(() => groupByStatus(tasks), [tasks])
  const projectMap = useMemo(() => new Map(projects.map((p) => [p.id, p])), [projects])
  const { members, byId: memberMap } = useMembers()
  const [activeTask, setActiveTask] = useState<Task | null>(null)

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
    useSensor(KeyboardSensor, { keyboardCodes: { start: ['Space'], cancel: ['Escape'], end: ['Space', 'Enter'] } }),
  )

  const onDragStart = ({ active }: DragStartEvent) => setActiveTask((active.data.current?.task as Task) ?? null)

  const onDragEnd = ({ active, over }: DragEndEvent) => {
    setActiveTask(null)
    const task = active.data.current?.task as Task | undefined
    if (!task || !over) return
    const status = over.data.current?.status as TaskStatus | undefined
    if (!status) return
    const column = columns[status].filter((t) => t.id !== task.id)
    let beforeId: string | null = null
    const overTaskId = over.data.current?.taskId as string | undefined
    if (overTaskId && overTaskId !== task.id) {
      // Dropping on the lower half of a card inserts after it.
      const dragged = active.rect.current.translated
      const below = dragged ? dragged.top + dragged.height / 2 > over.rect.top + over.rect.height / 2 : false
      const index = column.findIndex((t) => t.id === overTaskId)
      beforeId = below ? (column[index + 1]?.id ?? null) : overTaskId
    } else if (overTaskId === task.id) {
      return
    }
    const order = orderForInsert(column, beforeId)
    if (status === task.status && order === task.order) return
    void updateTask(task.id, { status, order })
  }

  const announcements: Announcements = {
    onDragStart: ({ active }) => `Picked up task ${(active.data.current?.task as Task | undefined)?.title ?? ''}.`,
    onDragOver: ({ over }) => (over ? `Over ${TASK_STATUS_META[over.data.current?.status as TaskStatus]?.label ?? ''} column.` : 'Not over a column.'),
    onDragEnd: ({ over }) => (over ? `Dropped in ${TASK_STATUS_META[over.data.current?.status as TaskStatus]?.label ?? ''}.` : 'Drop cancelled.'),
    onDragCancel: () => 'Drag cancelled.',
  }

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={collisionDetection}
      onDragStart={onDragStart}
      onDragEnd={onDragEnd}
      onDragCancel={() => setActiveTask(null)}
      accessibility={{
        announcements,
        screenReaderInstructions: { draggable: 'Press Space to pick up the task, arrow keys to move it, and Space again to drop. Press Enter to open it.' },
      }}
    >
      <div className={cn('grid min-h-0 flex-1 auto-cols-[minmax(272px,1fr)] grid-flow-col gap-3 overflow-x-auto', className)}>
        {TASK_STATUSES.map((status) => (
          <Column
            key={status}
            status={status}
            tasks={columns[status]}
            projectMap={projectMap}
            members={members}
            memberMap={memberMap}
            workspaceId={workspaceId}
            projectId={projectId}
          />
        ))}
      </div>
      <DragOverlay dropAnimation={{ duration: 160, easing: 'ease-out' }}>
        {activeTask ? (
          <TaskCard
            task={activeTask}
            project={activeTask.projectId ? projectMap.get(activeTask.projectId) : undefined}
            assignee={activeTask.assigneeId ? memberMap.get(activeTask.assigneeId) : undefined}
            overlay
          />
        ) : null}
      </DragOverlay>
    </DndContext>
  )
}

function Column({
  status,
  tasks,
  projectMap,
  members,
  memberMap,
  workspaceId,
  projectId,
}: {
  status: TaskStatus
  tasks: Task[]
  projectMap: Map<string, Project>
  members: Member[]
  memberMap: Map<string, Member>
  workspaceId: string
  projectId: string | null
}) {
  const { setNodeRef, isOver } = useDroppable({ id: `col:${status}`, data: { status } })
  const [adding, setAdding] = useState(false)
  const canEdit = useCan('content.edit')
  const meta = TASK_STATUS_META[status]

  return (
    <section
      ref={setNodeRef}
      aria-label={`${meta.label} column`}
      className={cn('flex min-h-0 flex-col rounded-xl border border-transparent bg-surface-2/60 transition-colors', isOver && 'border-accent/50 bg-accent-soft/60')}
    >
      <header className="flex h-11 shrink-0 items-center gap-2 px-3">
        <span className={cn('size-2 rounded-full', meta.dot)} />
        <h2 className="text-[13px] font-semibold">{meta.label}</h2>
        <span className="text-xs text-fg-subtle tabular-nums">{tasks.length}</span>
        <div className="flex-1" />
        {canEdit && (
          <button
            type="button"
            aria-label={`Add task to ${meta.label}`}
            title="Add task"
            onClick={() => setAdding(true)}
            className="flex size-6 items-center justify-center rounded-md text-fg-subtle hover:bg-line hover:text-fg"
          >
            <Plus className="size-3.5" />
          </button>
        )}
      </header>
      <div className="flex min-h-24 flex-1 flex-col gap-2 overflow-y-auto px-2 pb-2">
        {adding && <QuickAdd status={status} workspaceId={workspaceId} projectId={projectId} onClose={() => setAdding(false)} />}
        {tasks.map((task) => (
          <DraggableCard
            key={task.id}
            task={task}
            project={task.projectId ? projectMap.get(task.projectId) : undefined}
            assignee={task.assigneeId ? memberMap.get(task.assigneeId) : undefined}
            members={members}
          />
        ))}
        {tasks.length === 0 && !adding && !canEdit && (
          <p className="flex h-20 items-center justify-center rounded-lg border border-dashed border-line-strong text-xs text-fg-subtle">No tasks</p>
        )}
        {tasks.length === 0 && !adding && canEdit && (
          <button
            type="button"
            onClick={() => setAdding(true)}
            className="flex h-20 items-center justify-center rounded-lg border border-dashed border-line-strong text-xs text-fg-subtle hover:border-accent hover:text-accent"
          >
            Drop tasks here or click to add
          </button>
        )}
      </div>
    </section>
  )
}

function DraggableCard({ task, project, assignee, members }: { task: Task; project?: Project; assignee?: Member; members: Member[] }) {
  const canEdit = useCan('content.edit')
  // Viewers can open cards but not move them.
  const drag = useDraggable({ id: `task:${task.id}`, data: { task }, disabled: !canEdit })
  const drop = useDroppable({ id: `card:${task.id}`, data: { status: task.status, taskId: task.id } })
  const openTask = useQuickCreateStore((s) => s.openTask)
  const open = () => openTask({ taskId: task.id })

  return (
    <TaskCard
      ref={(node) => {
        drag.setNodeRef(node)
        drop.setNodeRef(node)
      }}
      task={task}
      project={project}
      assignee={assignee}
      dragging={drag.isDragging}
      {...drag.attributes}
      {...drag.listeners}
      aria-roledescription="Draggable task"
      aria-label={`${task.title}. ${TASK_STATUS_META[task.status].label}, ${task.priority} priority${assignee ? `, assigned to ${assignee.name}` : ''}.`}
      onClick={open}
      onKeyDown={(e) => {
        drag.listeners?.onKeyDown?.(e)
        if (e.key === 'Enter' && !drag.isDragging) open()
      }}
      onContextMenu={canEdit ? (e) => openContextMenu(e, taskMenu(task, members)) : undefined}
      className={cn(canEdit ? 'cursor-grab active:cursor-grabbing' : 'cursor-pointer', drop.isOver && !drag.isDragging && 'border-accent')}
    />
  )
}

function QuickAdd({ status, workspaceId, projectId, onClose }: { status: TaskStatus; workspaceId: string; projectId: string | null; onClose: () => void }) {
  const [title, setTitle] = useState('')

  const submit = (e: FormEvent) => {
    e.preventDefault()
    const value = title.trim()
    if (!value) return onClose()
    // Clear immediately so the next title can be typed while this one saves.
    setTitle('')
    createTask({ workspaceId, title: value, status, projectId }).catch((error) => {
      setTitle(value)
      toast.error(error instanceof ValidationError ? error.message : error)
    })
  }

  return (
    <form onSubmit={submit} className="rounded-lg border border-accent bg-surface p-2 shadow-sm">
      <label className="sr-only" htmlFor={`quick-add-${status}`}>
        New task title
      </label>
      <input
        id={`quick-add-${status}`}
        autoFocus
        value={title}
        maxLength={200}
        onChange={(e) => setTitle(e.target.value)}
        onKeyDown={(e) => e.key === 'Escape' && onClose()}
        onBlur={() => !title.trim() && onClose()}
        placeholder="Task title, then Enter"
        className="w-full bg-transparent text-sm outline-none placeholder:text-fg-subtle"
      />
    </form>
  )
}
