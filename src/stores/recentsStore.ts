import { create } from 'zustand'
import { repositories, type EntityType, type RecentVisit } from '@/data'

interface RecentsState {
  items: RecentVisit[]
  workspaceId: string | null
  load(workspaceId: string): Promise<void>
  touch(workspaceId: string, entityType: EntityType, entityId: string): Promise<void>
  forget(entityType: EntityType, entityId: string): void
}

const LIMIT = 15

export const useRecentsStore = create<RecentsState>()((set, get) => ({
  items: [],
  workspaceId: null,
  async load(workspaceId) {
    set({ workspaceId })
    const items = await repositories.recents.listByWorkspace(workspaceId, LIMIT)
    if (get().workspaceId === workspaceId) set({ items })
  },
  async touch(workspaceId, entityType, entityId) {
    const visit = await repositories.recents.touch(workspaceId, entityType, entityId)
    if (get().workspaceId !== workspaceId) return
    set((s) => ({ items: [visit, ...s.items.filter((v) => v.id !== visit.id)].slice(0, LIMIT) }))
  },
  forget(entityType, entityId) {
    set((s) => ({ items: s.items.filter((v) => !(v.entityType === entityType && v.entityId === entityId)) }))
  },
}))
