import { Navigate } from 'react-router'
import { paths } from '@/lib/routes'
import { getLastWorkspaceId, useWorkspaceStore } from '@/stores/workspaceStore'
import { FullScreenSpinner } from './WorkspaceLayout'

export function RootRedirect() {
  const { status, workspaces } = useWorkspaceStore()
  if (status !== 'ready') return <FullScreenSpinner />
  if (workspaces.length === 0) return <Navigate to="/welcome" replace />
  const last = getLastWorkspaceId()
  const target = workspaces.find((w) => w.id === last) ?? workspaces[0]
  return <Navigate to={paths.workspace(target.id)} replace />
}
