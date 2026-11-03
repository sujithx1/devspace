import { create } from 'zustand'
import type { ProjectInput, TaskInput } from '@/data'

type TaskDefaults = Partial<Omit<TaskInput, 'workspaceId'>>
type ProjectDefaults = Partial<Omit<ProjectInput, 'workspaceId'>>

interface QuickCreateState {
  /** `taskId` set → edit mode; otherwise creates a task using `defaults`. */
  task: { open: boolean; taskId?: string; defaults?: TaskDefaults }
  project: { open: boolean; projectId?: string; defaults?: ProjectDefaults }
  openTask(opts?: { taskId?: string; defaults?: TaskDefaults }): void
  closeTask(): void
  openProject(opts?: { projectId?: string; defaults?: ProjectDefaults }): void
  closeProject(): void
}

/** Global entry points for the task and project editors (used by shortcuts, palette, dashboard…). */
export const useQuickCreateStore = create<QuickCreateState>()((set) => ({
  task: { open: false },
  project: { open: false },
  openTask: (opts = {}) => set({ task: { open: true, ...opts } }),
  closeTask: () => set((s) => ({ task: { ...s.task, open: false } })),
  openProject: (opts = {}) => set({ project: { open: true, ...opts } }),
  closeProject: () => set((s) => ({ project: { ...s.project, open: false } })),
}))
