import { repositories } from '@/data'
import { createCollectionStore } from './createCollectionStore'

/** One store per workspace-scoped collection. */
export const useMembersStore = createCollectionStore(repositories.members, 'members.manage')
export const useFoldersStore = createCollectionStore(repositories.folders)
export const useNotesStore = createCollectionStore(repositories.notes)
export const useDocsStore = createCollectionStore(repositories.docs)
export const useTasksStore = createCollectionStore(repositories.tasks)
export const useProjectsStore = createCollectionStore(repositories.projects)
export const useDrawingsStore = createCollectionStore(repositories.drawings)

export const collectionStores = [
  useMembersStore,
  useFoldersStore,
  useNotesStore,
  useDocsStore,
  useTasksStore,
  useProjectsStore,
  useDrawingsStore,
] as const
