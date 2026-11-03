import { create } from 'zustand'
import { errorMessage, repositories, type Workspace, type WorkspaceInput } from '@/data'
import { collectionStores } from './collections'
import { checkPermission } from './guard'
import { useRecentsStore } from './recentsStore'
import type { LoadStatus } from './createCollectionStore'

const LAST_WORKSPACE_KEY = 'devspace:lastWorkspace'

interface WorkspaceState {
  workspaces: Workspace[]
  activeId: string | null
  status: LoadStatus
  error: string | null
  init(): Promise<void>
  /** Re-reads the workspace list (e.g. after an import). */
  refresh(): Promise<void>
  activate(id: string): Promise<void>
  /** Creates a workspace. Group workspaces start with an owner member named `ownerName`. */
  create(input: WorkspaceInput, opts?: { ownerName?: string }): Promise<Workspace>
  update(id: string, patch: Partial<WorkspaceInput>): Promise<Workspace>
  remove(id: string): Promise<void>
}

export function getLastWorkspaceId(): string | null {
  try {
    return localStorage.getItem(LAST_WORKSPACE_KEY)
  } catch {
    return null
  }
}

export const useWorkspaceStore = create<WorkspaceState>()((set, get) => ({
  workspaces: [],
  activeId: null,
  status: 'idle',
  error: null,

  async init() {
    if (get().status === 'loading' || get().status === 'ready') return
    set({ status: 'loading', error: null })
    try {
      const workspaces = await repositories.workspaces.list()
      set({ workspaces, status: 'ready' })
    } catch (error) {
      set({ status: 'error', error: errorMessage(error, 'Could not open local database') })
    }
  },

  async refresh() {
    set({ workspaces: await repositories.workspaces.list() })
  },

  /** Makes `id` the active workspace and loads every collection for it. */
  async activate(id) {
    if (get().activeId === id) return
    set({ activeId: id })
    try {
      localStorage.setItem(LAST_WORKSPACE_KEY, id)
    } catch {
      // Remembering the last workspace is a convenience only.
    }
    await Promise.all([
      ...collectionStores.map((store) => store.getState().load(id)),
      useRecentsStore.getState().load(id),
    ])
  },

  async create(input, opts = {}) {
    const workspace = await repositories.workspaces.create(input)
    if (workspace.type === 'group') {
      try {
        await repositories.members.create({ workspaceId: workspace.id, name: opts.ownerName?.trim() || 'You', role: 'owner' })
      } catch (error) {
        // Never leave a half-created group workspace behind.
        await repositories.workspaces.remove(workspace.id)
        throw error
      }
    }
    set((s) => ({ workspaces: [...s.workspaces, workspace] }))
    return workspace
  },

  async update(id, patch) {
    if (id === get().activeId) checkPermission('workspace.manage')
    const workspace = await repositories.workspaces.update(id, patch)
    set((s) => ({ workspaces: s.workspaces.map((w) => (w.id === id ? workspace : w)) }))
    return workspace
  },

  async remove(id) {
    if (id === get().activeId) checkPermission('workspace.manage')
    await repositories.workspaces.remove(id)
    set((s) => ({ workspaces: s.workspaces.filter((w) => w.id !== id), activeId: s.activeId === id ? null : s.activeId }))
    if (get().activeId === null) collectionStores.forEach((store) => store.getState().reset())
  },
}))

/** The active workspace, or undefined while routing resolves it. */
export function useActiveWorkspace(): Workspace | undefined {
  return useWorkspaceStore((s) => s.workspaces.find((w) => w.id === s.activeId))
}

/** Active workspace id; only call inside workspace routes where it is guaranteed. */
export function useWorkspaceId(): string {
  const id = useWorkspaceStore((s) => s.activeId)
  if (!id) throw new Error('useWorkspaceId used outside an active workspace')
  return id
}
