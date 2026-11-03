import type { Drawing, DrawingInput } from '@/data'
import { untitled } from '@/lib/entities'
import { useDrawingsStore } from '@/stores/collections'
import { confirmDialog } from '@/stores/dialogStore'
import { useRecentsStore } from '@/stores/recentsStore'
import { toast } from '@/stores/toastStore'

export async function createDrawing(workspaceId: string, input: Partial<DrawingInput> = {}): Promise<Drawing | null> {
  try {
    return await useDrawingsStore.getState().create({ title: '', ...input, workspaceId })
  } catch (error) {
    toast.error(error, 'Could not create drawing')
    return null
  }
}

export async function duplicateDrawing(drawing: Drawing): Promise<Drawing | null> {
  try {
    const copy = await useDrawingsStore.getState().create({
      workspaceId: drawing.workspaceId,
      folderId: drawing.folderId,
      projectId: drawing.projectId,
      title: `${untitled(drawing.title)} (copy)`.slice(0, 200),
      scene: structuredClone(drawing.scene),
      thumbnail: drawing.thumbnail,
    })
    toast.success('Drawing duplicated')
    return copy
  } catch (error) {
    toast.error(error, 'Could not duplicate drawing')
    return null
  }
}

export async function updateDrawing(id: string, patch: Partial<DrawingInput>): Promise<void> {
  try {
    await useDrawingsStore.getState().update(id, patch)
  } catch (error) {
    toast.error(error, 'Could not save drawing')
  }
}

export async function deleteDrawing(drawing: Drawing): Promise<boolean> {
  const ok = await confirmDialog({
    title: 'Delete drawing?',
    description: `“${untitled(drawing.title)}” will be permanently deleted.`,
    confirmLabel: 'Delete',
    destructive: true,
  })
  if (!ok) return false
  try {
    await useDrawingsStore.getState().remove(drawing.id)
    useRecentsStore.getState().forget('drawing', drawing.id)
    toast.success('Drawing deleted')
    return true
  } catch (error) {
    toast.error(error, 'Could not delete drawing')
    return false
  }
}
