import { create } from 'zustand'
import type { CollectionRepository, WorkspaceEntity } from '@/data'
import { errorMessage } from '@/data'
import { checkPermission, type Permission } from './guard'

export type LoadStatus = 'idle' | 'loading' | 'ready' | 'error'

export interface CollectionState<T extends WorkspaceEntity, C, U> {
  items: T[]
  status: LoadStatus
  error: string | null
  workspaceId: string | null
  load(workspaceId: string): Promise<void>
  reset(): void
  create(input: C): Promise<T>
  /** Applies the patch optimistically, then persists it. Reverts on failure. */
  update(id: string, patch: U): Promise<T>
  remove(id: string): Promise<void>
}

/**
 * Builds a Zustand store that mirrors one repository collection for the active
 * workspace. Components read from the store; all writes go through the
 * repository so the store never diverges from persisted data for long.
 */
export function createCollectionStore<T extends WorkspaceEntity, C, U>(
  repo: CollectionRepository<T, C, U>,
  /** Permission required for create/update/remove. */
  permission: Permission = 'content.edit',
) {
  // Tracks in-flight writes per entity so a slow, older write never overwrites newer optimistic state.
  const writeSeq = new Map<string, number>()

  return create<CollectionState<T, C, U>>()((set, get) => ({
    items: [],
    status: 'idle',
    error: null,
    workspaceId: null,

    async load(workspaceId) {
      set({ status: 'loading', error: null, workspaceId })
      try {
        const items = await repo.listByWorkspace(workspaceId)
        if (get().workspaceId !== workspaceId) return
        set({ items, status: 'ready' })
      } catch (error) {
        if (get().workspaceId !== workspaceId) return
        set({ status: 'error', error: errorMessage(error, 'Could not load data') })
      }
    },

    reset() {
      set({ items: [], status: 'idle', error: null, workspaceId: null })
    },

    async create(input) {
      checkPermission(permission)
      const item = await repo.create(input)
      if (item.workspaceId === get().workspaceId) set((s) => ({ items: [...s.items, item] }))
      return item
    },

    async update(id, patch) {
      checkPermission(permission)
      const previous = get().items.find((i) => i.id === id)
      const seq = (writeSeq.get(id) ?? 0) + 1
      writeSeq.set(id, seq)
      if (previous) {
        const optimistic = { ...previous, ...stripUndefined(patch as object), updatedAt: Date.now() } as T
        set((s) => ({ items: s.items.map((i) => (i.id === id ? optimistic : i)) }))
      }
      try {
        const saved = await repo.update(id, patch)
        if (writeSeq.get(id) === seq) {
          set((s) => ({ items: s.items.map((i) => (i.id === id ? saved : i)) }))
        }
        return saved
      } catch (error) {
        if (previous && writeSeq.get(id) === seq) {
          set((s) => ({ items: s.items.map((i) => (i.id === id ? previous : i)) }))
        }
        throw error
      }
    },

    async remove(id) {
      checkPermission(permission)
      await repo.remove(id)
      set((s) => ({ items: s.items.filter((i) => i.id !== id) }))
    },
  }))
}

function stripUndefined(obj: object) {
  return Object.fromEntries(Object.entries(obj).filter(([, v]) => v !== undefined))
}
