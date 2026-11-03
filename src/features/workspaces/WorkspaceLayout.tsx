import { useEffect } from 'react'
import { Link, useParams } from 'react-router'
import { AppShell } from '@/components/layout/AppShell'
import { Spinner } from '@/components/ui/States'
import { useWorkspaceStore } from '@/stores/workspaceStore'

/** Resolves `:workspaceId` from the URL, activates it, and renders the app shell. */
export function WorkspaceLayout() {
  const { workspaceId = '' } = useParams()
  const status = useWorkspaceStore((s) => s.status)
  const exists = useWorkspaceStore((s) => s.workspaces.some((w) => w.id === workspaceId))
  const activeId = useWorkspaceStore((s) => s.activeId)
  const activate = useWorkspaceStore((s) => s.activate)

  useEffect(() => {
    if (status === 'ready' && exists) void activate(workspaceId)
  }, [status, exists, workspaceId, activate])

  if (status !== 'ready') return <FullScreenSpinner />
  if (!exists) {
    return (
      <div className="flex h-full flex-col items-center justify-center gap-3 p-6 text-center">
        <h1 className="text-lg font-semibold">Workspace not found</h1>
        <p className="text-sm text-fg-muted">It may have been deleted, or the link is incorrect.</p>
        <Link to="/" className="text-sm font-medium text-accent hover:underline">
          Go to my workspaces
        </Link>
      </div>
    )
  }
  if (activeId !== workspaceId) return <FullScreenSpinner />
  return <AppShell />
}

export function FullScreenSpinner() {
  return (
    <div className="flex h-full items-center justify-center">
      <Spinner />
    </div>
  )
}
