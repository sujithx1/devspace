import type { Folder, FolderKind } from '@/data'
import { useFoldersStore } from '@/stores/collections'
import { useDocsStore, useDrawingsStore, useNotesStore } from '@/stores/collections'
import { confirmDialog, promptDialog } from '@/stores/dialogStore'
import { toast } from '@/stores/toastStore'

const validateName = (value: string) => (value.length > 60 ? 'Folder name must be 60 characters or fewer' : null)

export async function createFolder(workspaceId: string, kind: FolderKind): Promise<Folder | null> {
  const name = await promptDialog({ title: 'New folder', label: 'Folder name', placeholder: 'e.g. Architecture', confirmLabel: 'Create', validate: validateName })
  if (!name) return null
  try {
    const folder = await useFoldersStore.getState().create({ workspaceId, kind, name })
    toast.success(`Folder “${folder.name}” created`)
    return folder
  } catch (error) {
    toast.error(error, 'Could not create folder')
    return null
  }
}

export async function renameFolder(folder: Folder): Promise<void> {
  const name = await promptDialog({ title: 'Rename folder', label: 'Folder name', initialValue: folder.name, validate: validateName })
  if (!name || name === folder.name) return
  try {
    await useFoldersStore.getState().update(folder.id, { name })
  } catch (error) {
    toast.error(error, 'Could not rename folder')
  }
}

/** Deletes a folder. Its items are kept and moved to the top level. */
export async function deleteFolder(folder: Folder): Promise<boolean> {
  const ok = await confirmDialog({
    title: 'Delete folder?',
    description: `“${folder.name}” will be removed. Items inside it are kept and moved out of the folder.`,
    confirmLabel: 'Delete folder',
    destructive: true,
  })
  if (!ok) return false
  try {
    await useFoldersStore.getState().remove(folder.id)
    // The repository unlinked items in storage; reflect that in the in-memory stores.
    const ws = folder.workspaceId
    const store = folder.kind === 'note' ? useNotesStore : folder.kind === 'doc' ? useDocsStore : useDrawingsStore
    await store.getState().load(ws)
    toast.success('Folder deleted')
    return true
  } catch (error) {
    toast.error(error, 'Could not delete folder')
    return false
  }
}
