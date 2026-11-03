import { motion } from 'framer-motion'
import { BookOpen, CheckSquare, FileText, FolderKanban, PenTool } from 'lucide-react'
import { useState, type FormEvent } from 'react'
import { Navigate, useNavigate } from 'react-router'
import { Button } from '@/components/ui/Button'
import { Field, Input } from '@/components/ui/Field'
import { ValidationError, type WorkspaceType } from '@/data'
import { paths } from '@/lib/routes'
import { toast } from '@/stores/toastStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { Logo } from '@/components/layout/Logo'
import { WorkspaceTypePicker } from './WorkspaceTypePicker'

const FEATURES = [
  { icon: FileText, label: 'Notes' },
  { icon: CheckSquare, label: 'Tasks' },
  { icon: FolderKanban, label: 'Projects' },
  { icon: BookOpen, label: 'Docs' },
  { icon: PenTool, label: 'Whiteboards' },
]

export function OnboardingPage() {
  const navigate = useNavigate()
  const { create, workspaces, status } = useWorkspaceStore()
  const [name, setName] = useState('')
  const [type, setType] = useState<WorkspaceType>('private')
  const [ownerName, setOwnerName] = useState('')
  const [error, setError] = useState<string>()
  const [ownerError, setOwnerError] = useState<string>()
  const [saving, setSaving] = useState(false)

  if (status === 'ready' && workspaces.length > 0) return <Navigate to={paths.workspace(workspaces[0].id)} replace />

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (type === 'group' && !ownerName.trim()) return setOwnerError('Your name is required for a group workspace')
    setSaving(true)
    try {
      const ws = await create({ name, type }, { ownerName })
      navigate(paths.workspace(ws.id), { replace: true })
    } catch (err) {
      if (err instanceof ValidationError) setError(err.message)
      else toast.error(err)
      setSaving(false)
    }
  }

  return (
    <main className="flex min-h-full items-center justify-center bg-canvas p-6">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.35, ease: 'easeOut' }}
        className="w-full max-w-md"
      >
        <Logo className="mb-8" />
        <h1 className="text-2xl font-semibold tracking-tight">Set up your workspace</h1>
        <p className="mt-2 text-sm leading-relaxed text-fg-muted">
          DevSpace keeps your notes, tasks, projects, docs and diagrams together. Everything is stored locally in this browser.
        </p>
        <ul className="mt-5 flex flex-wrap gap-2">
          {FEATURES.map(({ icon: Icon, label }) => (
            <li key={label} className="flex items-center gap-1.5 rounded-full border border-line bg-surface px-2.5 py-1 text-xs text-fg-muted">
              <Icon className="size-3.5" />
              {label}
            </li>
          ))}
        </ul>
        <form onSubmit={submit} className="mt-8 flex flex-col gap-4 rounded-xl border border-line bg-surface p-5 shadow-sm">
          <Field label="Workspace name" error={error}>
            {(props) => (
              <Input
                {...props}
                autoFocus
                value={name}
                maxLength={60}
                placeholder="e.g. Personal, Acme Engineering"
                onChange={(e) => {
                  setName(e.target.value)
                  setError(undefined)
                }}
              />
            )}
          </Field>
          <WorkspaceTypePicker value={type} onChange={setType} />
          {type === 'group' && (
            <Field label="Your name" error={ownerError} hint="You'll be the owner. Add teammates later in Settings.">
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
          <Button type="submit" variant="primary" loading={saving} className="justify-center">
            Create workspace
          </Button>
        </form>
      </motion.div>
    </main>
  )
}
