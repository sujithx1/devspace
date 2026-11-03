import { useEffect, useState, type FormEvent } from 'react'
import { Button } from '@/components/ui/Button'
import { Field, Input } from '@/components/ui/Field'
import { Modal } from '@/components/ui/Modal'
import { ValidationError, type Workspace, type WorkspaceType } from '@/data'
import { cn } from '@/lib/utils'
import { toast } from '@/stores/toastStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { WorkspaceTypePicker } from './WorkspaceTypePicker'

export const WORKSPACE_ICONS = ['🚀', '💻', '🧪', '📦', '🛠️', '🧠', '⚡', '🌱', '🎯', '🔥', '🪐', '📚']

interface Props {
  open: boolean
  onClose: () => void
  /** When provided the dialog renames this workspace instead of creating one. */
  workspace?: Workspace
  onSaved?: (workspace: Workspace) => void
}

export function WorkspaceDialog({ open, onClose, workspace, onSaved }: Props) {
  const create = useWorkspaceStore((s) => s.create)
  const update = useWorkspaceStore((s) => s.update)
  const [name, setName] = useState('')
  const [icon, setIcon] = useState(WORKSPACE_ICONS[0])
  const [type, setType] = useState<WorkspaceType>('private')
  const [ownerName, setOwnerName] = useState('')
  const [error, setError] = useState<string>()
  const [ownerError, setOwnerError] = useState<string>()
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!open) return
    setName(workspace?.name ?? '')
    setIcon(workspace?.icon ?? WORKSPACE_ICONS[0])
    setType('private')
    setOwnerName('')
    setError(undefined)
    setOwnerError(undefined)
  }, [open, workspace])

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (!workspace && type === 'group' && !ownerName.trim()) return setOwnerError('Your name is required for a group workspace')
    setSaving(true)
    try {
      const saved = workspace ? await update(workspace.id, { name, icon }) : await create({ name, icon, type }, { ownerName })
      toast.success(workspace ? 'Workspace updated' : `Created “${saved.name}”`)
      onSaved?.(saved)
      onClose()
    } catch (err) {
      if (err instanceof ValidationError) setError(err.message)
      else toast.error(err)
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={workspace ? 'Rename workspace' : 'Create workspace'} size="sm">
      <form onSubmit={submit} className="flex flex-col gap-4">
        <Field label="Name" error={error}>
          {(props) => (
            <Input {...props} autoFocus data-autofocus value={name} maxLength={60} placeholder="e.g. Side projects" onChange={(e) => setName(e.target.value)} />
          )}
        </Field>
        {!workspace && (
          <>
            <WorkspaceTypePicker value={type} onChange={setType} />
            {type === 'group' && (
              <Field label="Your name" error={ownerError} hint="You'll be the workspace owner. Add teammates in Settings.">
                {(props) => (
                  <Input
                    {...props}
                    value={ownerName}
                    maxLength={60}
                    placeholder="e.g. Sujith"
                    onChange={(e) => {
                      setOwnerName(e.target.value)
                      setOwnerError(undefined)
                    }}
                  />
                )}
              </Field>
            )}
          </>
        )}
        <fieldset>
          <legend className="mb-1.5 text-xs font-medium text-fg-muted">Icon</legend>
          <div className="grid grid-cols-6 gap-1.5">
            {WORKSPACE_ICONS.map((emoji) => (
              <button
                key={emoji}
                type="button"
                aria-label={`Use ${emoji} icon`}
                aria-pressed={icon === emoji}
                onClick={() => setIcon(emoji)}
                className={cn(
                  'flex h-9 items-center justify-center rounded-md border text-lg transition-colors',
                  icon === emoji ? 'border-accent bg-accent-soft' : 'border-line hover:bg-surface-2',
                )}
              >
                {emoji}
              </button>
            ))}
          </div>
        </fieldset>
        <div className="flex justify-end gap-2 pt-1">
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" loading={saving}>
            {workspace ? 'Save' : 'Create workspace'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}
