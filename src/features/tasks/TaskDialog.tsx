import { Trash2 } from 'lucide-react'
import { useEffect, useState, type FormEvent } from 'react'
import { ProjectSelect } from '@/components/shared/ProjectSelect'
import { Button } from '@/components/ui/Button'
import { Field, Input, Select, Textarea } from '@/components/ui/Field'
import { Modal } from '@/components/ui/Modal'
import { PRIORITIES, TASK_STATUSES, ValidationError, type Priority, type Task, type TaskInput, type TaskStatus } from '@/data'
import { trackVisit } from '@/features/dashboard/useRecentEntries'
import { useMembers } from '@/features/members/useMembers'
import { PRIORITY_META, TASK_STATUS_META } from '@/lib/meta'
import { formatRelative } from '@/lib/utils'
import { useTasksStore } from '@/stores/collections'
import { useCan } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { toast } from '@/stores/toastStore'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { createTask, deleteTask } from './taskActions'

interface FormState {
  title: string
  description: string
  status: TaskStatus
  priority: Priority
  dueDate: string
  projectId: string | null
  assigneeId: string | null
}

const EMPTY: FormState = { title: '', description: '', status: 'todo', priority: 'medium', dueDate: '', projectId: null, assigneeId: null }

/** Global task create/edit dialog, driven by the quick-create store. */
export function TaskDialogHost() {
  const { task: state, closeTask } = useQuickCreateStore()
  const ws = useWorkspaceId()
  const existing = useTasksStore((s) => (state.taskId ? s.items.find((t) => t.id === state.taskId) : undefined))
  const editing = !!state.taskId

  useEffect(() => {
    if (state.open && existing?.id) trackVisit(ws, 'task', existing.id)
  }, [state.open, existing?.id, ws])

  // Task was deleted while the dialog was open.
  const open = state.open && (!editing || !!existing)
  const canEdit = useCan('content.edit')

  return (
    <Modal open={open} onClose={closeTask} title={!canEdit ? 'Task' : editing ? 'Edit task' : 'New task'} size="md">
      {open && <TaskForm key={state.taskId ?? 'new'} task={existing} defaults={state.defaults} workspaceId={ws} onDone={closeTask} />}
    </Modal>
  )
}

function TaskForm({
  task,
  defaults,
  workspaceId,
  onDone,
}: {
  task?: Task
  defaults?: Partial<Omit<TaskInput, 'workspaceId'>>
  workspaceId: string
  onDone: () => void
}) {
  const [form, setForm] = useState<FormState>(() =>
    task
      ? {
          title: task.title,
          description: task.description,
          status: task.status,
          priority: task.priority,
          dueDate: task.dueDate ?? '',
          projectId: task.projectId,
          assigneeId: task.assigneeId,
        }
      : {
          ...EMPTY,
          title: defaults?.title ?? '',
          description: defaults?.description ?? '',
          status: defaults?.status ?? EMPTY.status,
          priority: defaults?.priority ?? EMPTY.priority,
          dueDate: defaults?.dueDate ?? '',
          projectId: defaults?.projectId ?? null,
          assigneeId: defaults?.assigneeId ?? null,
        },
  )
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [saving, setSaving] = useState(false)
  const { isGroup, members } = useMembers()
  const canEdit = useCan('content.edit')

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setForm((f) => ({ ...f, [key]: value }))
    setErrors((e) => ({ ...e, [key]: '' }))
  }

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (!form.title.trim()) return setErrors({ title: 'Task title is required' })
    setSaving(true)
    const payload = { ...form, title: form.title.trim(), dueDate: form.dueDate || null }
    try {
      if (task) {
        const saved = await useTasksStore.getState().update(task.id, payload)
        if (saved) toast.success('Task updated')
      } else {
        await createTask({ ...payload, workspaceId })
      }
      onDone()
    } catch (error) {
      if (error instanceof ValidationError) setErrors(error.fieldErrors)
      else toast.error(error)
    } finally {
      setSaving(false)
    }
  }

  return (
    <form onSubmit={submit} className="flex flex-col gap-4">
      {/* Viewers see the same form with every control disabled. */}
      <fieldset disabled={!canEdit} className="flex min-w-0 flex-col gap-4">
        <Field label="Title" error={errors.title}>
          {(p) => <Input {...p} autoFocus data-autofocus value={form.title} maxLength={200} placeholder="What needs to be done?" onChange={(e) => set('title', e.target.value)} />}
        </Field>
        <Field label="Description" error={errors.description}>
          {(p) => (
            <Textarea {...p} value={form.description} maxLength={10_000} rows={4} placeholder="Add details, acceptance criteria, links…" onChange={(e) => set('description', e.target.value)} />
          )}
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Status">
            {(p) => (
              <Select {...p} value={form.status} onChange={(e) => set('status', e.target.value as TaskStatus)}>
                {TASK_STATUSES.map((s) => (
                  <option key={s} value={s}>
                    {TASK_STATUS_META[s].label}
                  </option>
                ))}
              </Select>
            )}
          </Field>
          <Field label="Priority">
            {(p) => (
              <Select {...p} value={form.priority} onChange={(e) => set('priority', e.target.value as Priority)}>
                {PRIORITIES.map((pr) => (
                  <option key={pr} value={pr}>
                    {PRIORITY_META[pr].label}
                  </option>
                ))}
              </Select>
            )}
          </Field>
          <Field label="Due date" error={errors.dueDate}>
            {(p) => <Input {...p} type="date" value={form.dueDate} onChange={(e) => set('dueDate', e.target.value)} />}
          </Field>
          <Field label="Project">{(p) => <ProjectSelect id={p.id} value={form.projectId} onChange={(id) => set('projectId', id)} />}</Field>
          {isGroup && (
            <Field label="Assignee" className="col-span-2">
              {(p) => (
                <Select {...p} value={form.assigneeId ?? ''} onChange={(e) => set('assigneeId', e.target.value || null)}>
                  <option value="">Unassigned</option>
                  {members.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.name}
                    </option>
                  ))}
                </Select>
              )}
            </Field>
          )}
        </div>
      </fieldset>
      <div className="flex items-center gap-2 pt-1">
        {task && canEdit && (
          <>
            <Button
              variant="ghost"
              className="text-danger hover:text-danger"
              onClick={async () => {
                if (await deleteTask(task)) onDone()
              }}
            >
              <Trash2 className="size-4" /> Delete
            </Button>
            <span className="hidden text-xs text-fg-subtle sm:inline">Updated {formatRelative(task.updatedAt)}</span>
          </>
        )}
        {task && !canEdit && <span className="text-xs text-fg-subtle">Read-only · Updated {formatRelative(task.updatedAt)}</span>}
        <div className="flex-1" />
        <Button variant="ghost" onClick={onDone}>
          {canEdit ? 'Cancel' : 'Close'}
        </Button>
        {canEdit && (
          <Button type="submit" variant="primary" loading={saving}>
            {task ? 'Save changes' : 'Create task'}
          </Button>
        )}
      </div>
    </form>
  )
}
