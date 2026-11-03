import { useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/Button'
import { Field, Input, Select, Textarea } from '@/components/ui/Field'
import { Modal } from '@/components/ui/Modal'
import { PRIORITIES, PROJECT_COLORS, PROJECT_STATUSES, ValidationError, type Priority, type Project, type ProjectColor, type ProjectStatus } from '@/data'
import { PRIORITY_META, PROJECT_COLOR_META, PROJECT_STATUS_META } from '@/lib/meta'
import { paths } from '@/lib/routes'
import { cn } from '@/lib/utils'
import { useProjectsStore } from '@/stores/collections'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { toast } from '@/stores/toastStore'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { useNavigate } from 'react-router'

interface FormState {
  name: string
  description: string
  status: ProjectStatus
  priority: Priority
  startDate: string
  dueDate: string
  color: ProjectColor
}

export function ProjectDialogHost() {
  const { project: state, closeProject } = useQuickCreateStore()
  const existing = useProjectsStore((s) => (state.projectId ? s.items.find((p) => p.id === state.projectId) : undefined))
  const editing = !!state.projectId
  const open = state.open && (!editing || !!existing)
  return (
    <Modal open={open} onClose={closeProject} title={editing ? 'Edit project' : 'New project'} size="md">
      {open && <ProjectForm key={state.projectId ?? 'new'} project={existing} onDone={closeProject} />}
    </Modal>
  )
}

function ProjectForm({ project, onDone }: { project?: Project; onDone: () => void }) {
  const ws = useWorkspaceId()
  const navigate = useNavigate()
  const [form, setForm] = useState<FormState>(() => ({
    name: project?.name ?? '',
    description: project?.description ?? '',
    status: project?.status ?? 'active',
    priority: project?.priority ?? 'medium',
    startDate: project?.startDate ?? '',
    dueDate: project?.dueDate ?? '',
    color: project?.color ?? 'indigo',
  }))
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [saving, setSaving] = useState(false)

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setForm((f) => ({ ...f, [key]: value }))
    setErrors((e) => ({ ...e, [key]: '' }))
  }

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) return setErrors({ name: 'Project name is required' })
    if (form.startDate && form.dueDate && form.startDate > form.dueDate) return setErrors({ dueDate: 'Due date must be on or after the start date' })
    setSaving(true)
    const payload = { ...form, name: form.name.trim(), startDate: form.startDate || null, dueDate: form.dueDate || null }
    try {
      const store = useProjectsStore.getState()
      if (project) {
        await store.update(project.id, payload)
        toast.success('Project updated')
        onDone()
      } else {
        const created = await store.create({ ...payload, workspaceId: ws })
        toast.success(`Project “${created.name}” created`)
        onDone()
        navigate(paths.project(ws, created.id))
      }
    } catch (error) {
      if (error instanceof ValidationError) setErrors(error.fieldErrors)
      else toast.error(error)
    } finally {
      setSaving(false)
    }
  }

  return (
    <form onSubmit={submit} className="flex flex-col gap-4">
      <Field label="Name" error={errors.name}>
        {(p) => <Input {...p} autoFocus data-autofocus value={form.name} maxLength={80} placeholder="e.g. Payments API v2" onChange={(e) => set('name', e.target.value)} />}
      </Field>
      <Field label="Description" error={errors.description}>
        {(p) => <Textarea {...p} rows={3} maxLength={5000} value={form.description} placeholder="Goals, scope, links…" onChange={(e) => set('description', e.target.value)} />}
      </Field>
      <div className="grid grid-cols-2 gap-3">
        <Field label="Status">
          {(p) => (
            <Select {...p} value={form.status} onChange={(e) => set('status', e.target.value as ProjectStatus)}>
              {PROJECT_STATUSES.map((s) => (
                <option key={s} value={s}>
                  {PROJECT_STATUS_META[s].label}
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
        <Field label="Start date" error={errors.startDate}>
          {(p) => <Input {...p} type="date" value={form.startDate} onChange={(e) => set('startDate', e.target.value)} />}
        </Field>
        <Field label="Due date" error={errors.dueDate}>
          {(p) => <Input {...p} type="date" value={form.dueDate} min={form.startDate || undefined} onChange={(e) => set('dueDate', e.target.value)} />}
        </Field>
      </div>
      <fieldset>
        <legend className="mb-1.5 text-xs font-medium text-fg-muted">Color</legend>
        <div className="flex gap-2">
          {PROJECT_COLORS.map((c) => (
            <button
              key={c}
              type="button"
              aria-label={c}
              aria-pressed={form.color === c}
              onClick={() => set('color', c)}
              className={cn('size-6 rounded-full ring-offset-2 ring-offset-elevated transition', PROJECT_COLOR_META[c].swatch, form.color === c ? 'ring-2 ring-fg' : 'hover:scale-110')}
            />
          ))}
        </div>
      </fieldset>
      <div className="flex justify-end gap-2 pt-1">
        <Button variant="ghost" onClick={onDone}>
          Cancel
        </Button>
        <Button type="submit" variant="primary" loading={saving}>
          {project ? 'Save changes' : 'Create project'}
        </Button>
      </div>
    </form>
  )
}
