import { Download, HardDrive, Monitor, Moon, Pencil, Settings, Sun, Trash2, Upload } from 'lucide-react'
import { useEffect, useRef, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/Button'
import { Field, Input } from '@/components/ui/Field'
import { Modal } from '@/components/ui/Modal'
import { repositories, type WorkspaceType } from '@/data'
import { exportWorkspace, importWorkspace, parseBackup } from '@/data/backup'
import { convertToGroup, convertToPrivate } from '@/features/members/memberActions'
import { MembersCard } from '@/features/members/MembersCard'
import { WorkspaceDialog } from '@/features/workspaces/WorkspaceDialog'
import { WORKSPACE_TYPE_META, WorkspaceTypePicker } from '@/features/workspaces/WorkspaceTypePicker'
import { paths } from '@/lib/routes'
import { cn, downloadBlob, slugify, todayISO } from '@/lib/utils'
import { promptDialog } from '@/stores/dialogStore'
import { useCan } from '@/stores/permissions'
import { toast } from '@/stores/toastStore'
import { useUIStore, type ThemePreference } from '@/stores/uiStore'
import { useActiveWorkspace, useWorkspaceStore } from '@/stores/workspaceStore'

function formatBytes(bytes: number) {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 ** 2) return `${(bytes / 1024).toFixed(1)} KB`
  if (bytes < 1024 ** 3) return `${(bytes / 1024 ** 2).toFixed(1)} MB`
  return `${(bytes / 1024 ** 3).toFixed(1)} GB`
}

export function SettingsPage() {
  const workspace = useActiveWorkspace()
  const workspaces = useWorkspaceStore((s) => s.workspaces)
  const navigate = useNavigate()
  const theme = useUIStore((s) => s.theme)
  const setTheme = useUIStore((s) => s.setTheme)
  const [renameOpen, setRenameOpen] = useState(false)
  const canManage = useCan('workspace.manage')
  const [deleteOpen, setDeleteOpen] = useState(false)
  const [busy, setBusy] = useState<'export' | 'import' | null>(null)
  const [storage, setStorage] = useState<{ usage: number; quota: number } | null>(null)
  const fileInput = useRef<HTMLInputElement>(null)

  useEffect(() => {
    navigator.storage
      ?.estimate?.()
      .then((e) => setStorage({ usage: e.usage ?? 0, quota: e.quota ?? 0 }))
      .catch(() => setStorage(null))
  }, [])

  if (!workspace) return null

  const doExport = async () => {
    setBusy('export')
    try {
      const backup = await exportWorkspace(repositories, workspace.id)
      downloadBlob(new Blob([JSON.stringify(backup)], { type: 'application/json' }), `devspace-${slugify(workspace.name)}-${todayISO()}.json`)
      toast.success('Workspace exported')
    } catch (error) {
      toast.error(error, 'Export failed')
    } finally {
      setBusy(null)
    }
  }

  const doImport = async (file: File) => {
    setBusy('import')
    try {
      const backup = parseBackup(await file.text())
      const created = await importWorkspace(repositories, backup)
      await useWorkspaceStore.getState().refresh()
      toast.success(`Imported as “${created.name}”`)
      navigate(paths.workspace(created.id))
    } catch (error) {
      toast.error(error, 'Import failed')
    } finally {
      setBusy(null)
    }
  }

  const changeType = async (type: WorkspaceType) => {
    if (type === workspace.type) return
    try {
      if (type === 'private') return void (await convertToPrivate(workspace))
      const ownerName = await promptDialog({
        title: 'Make this a group workspace',
        label: 'Your name',
        placeholder: 'e.g. Sujith',
        confirmLabel: 'Continue',
        validate: (v) => (v.length > 60 ? 'Name must be 60 characters or fewer' : null),
      })
      if (ownerName) await convertToGroup(workspace, ownerName)
    } catch (error) {
      toast.error(error, 'Could not change workspace type')
    }
  }

  const TypeIcon = WORKSPACE_TYPE_META[workspace.type].icon

  const themes: { value: ThemePreference; label: string; icon: typeof Sun }[] = [
    { value: 'light', label: 'Light', icon: Sun },
    { value: 'dark', label: 'Dark', icon: Moon },
    { value: 'system', label: 'System', icon: Monitor },
  ]

  return (
    <>
      <PageHeader title="Settings" icon={<Settings className="size-4" />} />
      <div className="min-h-0 flex-1 overflow-y-auto">
        <div className="mx-auto flex max-w-2xl flex-col gap-6 p-4 md:p-8">
          <Card title="Workspace" description="Name and icon shown in the sidebar and workspace switcher.">
            <div className="flex items-center gap-3">
              <span className="flex size-11 items-center justify-center rounded-xl bg-surface-2 text-2xl">{workspace.icon}</span>
              <div className="min-w-0 flex-1">
                <p className="truncate font-medium">{workspace.name}</p>
                <p className="flex items-center gap-1 text-xs text-fg-subtle">
                  <TypeIcon className="size-3" /> {WORKSPACE_TYPE_META[workspace.type].label} workspace · Created {new Date(workspace.createdAt).toLocaleDateString()}
                </p>
              </div>
              {canManage && (
                <Button variant="outline" size="sm" onClick={() => setRenameOpen(true)}>
                  <Pencil className="size-3.5" /> Edit
                </Button>
              )}
            </div>
          </Card>

          <Card title="Workspace type" description="Private workspaces are just for you. Group workspaces have members, roles and task assignment.">
            <WorkspaceTypePicker value={workspace.type} disabled={!canManage} onChange={(t) => void changeType(t)} />
            {!canManage && <p className="mt-3 text-xs text-fg-subtle">Only owners can change workspace settings.</p>}
          </Card>

          {workspace.type === 'group' && (
            <Card title="Members" description="People in this workspace. Tasks can be assigned to any member.">
              <MembersCard workspace={workspace} />
            </Card>
          )}

          <Card title="Appearance" description="Theme applies to every workspace on this device.">
            <div role="radiogroup" aria-label="Theme" className="grid grid-cols-3 gap-2">
              {themes.map(({ value, label, icon: Icon }) => (
                <button
                  key={value}
                  type="button"
                  role="radio"
                  aria-checked={theme === value}
                  onClick={() => setTheme(value)}
                  className={cn(
                    'flex flex-col items-center gap-2 rounded-lg border p-3 text-sm font-medium transition-colors',
                    theme === value ? 'border-accent bg-accent-soft text-accent' : 'border-line text-fg-muted hover:border-line-strong hover:text-fg',
                  )}
                >
                  <Icon className="size-4.5" /> {label}
                </button>
              ))}
            </div>
          </Card>

          <Card title="Data" description="Everything is stored locally in this browser (IndexedDB). Export regularly to keep a backup.">
            <div className="flex flex-wrap gap-2">
              <Button variant="outline" onClick={() => void doExport()} loading={busy === 'export'}>
                <Download className="size-4" /> Export workspace (JSON)
              </Button>
              <Button variant="outline" onClick={() => fileInput.current?.click()} loading={busy === 'import'}>
                <Upload className="size-4" /> Import backup
              </Button>
              <input
                ref={fileInput}
                type="file"
                accept="application/json,.json"
                hidden
                onChange={(e) => {
                  const file = e.target.files?.[0]
                  e.target.value = ''
                  if (file) void doImport(file)
                }}
              />
            </div>
            {storage && storage.quota > 0 && (
              <p className="mt-4 flex items-center gap-2 text-xs text-fg-subtle">
                <HardDrive className="size-3.5" />
                Using {formatBytes(storage.usage)} of {formatBytes(storage.quota)} available browser storage
              </p>
            )}
          </Card>

          {canManage && (
            <Card title="Danger zone" description="Deleting a workspace permanently removes all of its notes, tasks, projects, docs and drawings." danger>
              <Button variant="danger" onClick={() => setDeleteOpen(true)}>
                <Trash2 className="size-4" /> Delete workspace
              </Button>
            </Card>
          )}
        </div>
      </div>
      <WorkspaceDialog open={renameOpen} workspace={workspace} onClose={() => setRenameOpen(false)} />
      <DeleteWorkspaceDialog
        open={deleteOpen}
        name={workspace.name}
        onClose={() => setDeleteOpen(false)}
        onConfirm={async () => {
          try {
            await useWorkspaceStore.getState().remove(workspace.id)
            toast.success('Workspace deleted')
            const next = workspaces.find((w) => w.id !== workspace.id)
            navigate(next ? paths.workspace(next.id) : '/welcome', { replace: true })
          } catch (error) {
            toast.error(error, 'Could not delete workspace')
          }
        }}
      />
    </>
  )
}

function Card({ title, description, danger, children }: { title: string; description?: string; danger?: boolean; children: ReactNode }) {
  return (
    <section className={cn('rounded-xl border bg-surface p-5', danger ? 'border-danger/40' : 'border-line')}>
      <h2 className={cn('text-sm font-semibold', danger && 'text-danger')}>{title}</h2>
      {description && <p className="mt-1 mb-4 text-sm text-fg-muted">{description}</p>}
      {children}
    </section>
  )
}

function DeleteWorkspaceDialog({ open, name, onClose, onConfirm }: { open: boolean; name: string; onClose: () => void; onConfirm: () => Promise<void> }) {
  const [value, setValue] = useState('')
  const [deleting, setDeleting] = useState(false)
  useEffect(() => {
    if (open) setValue('')
  }, [open])
  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Delete workspace?"
      description="This permanently deletes the workspace and everything in it. This cannot be undone."
      size="sm"
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant="danger"
            disabled={value !== name}
            loading={deleting}
            onClick={async () => {
              setDeleting(true)
              await onConfirm()
              setDeleting(false)
              onClose()
            }}
          >
            Delete forever
          </Button>
        </>
      }
    >
      <Field label={`Type “${name}” to confirm`}>{(p) => <Input {...p} autoFocus value={value} onChange={(e) => setValue(e.target.value)} />}</Field>
    </Modal>
  )
}
