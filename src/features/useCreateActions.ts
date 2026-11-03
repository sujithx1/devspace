import { useMemo } from 'react'
import { useNavigate } from 'react-router'
import type { TaskInput } from '@/data'
import { paths } from '@/lib/routes'
import { canNow, deniedMessage } from '@/stores/permissions'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { toast } from '@/stores/toastStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { createDrawing } from './drawings/drawingActions'
import { createPage } from './pages/pageActions'

/** Shared "create X" actions for quick-create buttons, the command palette and shortcuts. */
export function useCreateActions() {
  const navigate = useNavigate()
  const ws = useWorkspaceStore((s) => s.activeId)

  return useMemo(() => {
    // Checked up front so viewers get a clear message instead of an empty dialog or failed save.
    const allowed = () => {
      if (canNow('content.edit')) return true
      toast.info(deniedMessage('content.edit'))
      return false
    }
    const openTask = useQuickCreateStore.getState().openTask
    const openProject = useQuickCreateStore.getState().openProject
    return {
      newNote: async (input: { folderId?: string | null; projectId?: string | null } = {}) => {
        if (!ws || !allowed()) return
        const note = await createPage('note', ws, input)
        if (note) navigate(paths.note(ws, note.id))
      },
      newDoc: async (input: { folderId?: string | null; projectId?: string | null } = {}) => {
        if (!ws || !allowed()) return
        const doc = await createPage('doc', ws, input)
        if (doc) navigate(paths.doc(ws, doc.id))
      },
      newDrawing: async (input: { folderId?: string | null; projectId?: string | null } = {}) => {
        if (!ws || !allowed()) return
        const drawing = await createDrawing(ws, input)
        if (drawing) navigate(paths.drawing(ws, drawing.id))
      },
      newTask: (defaults?: Partial<Omit<TaskInput, 'workspaceId'>>) => allowed() && openTask({ defaults }),
      newProject: () => allowed() && openProject(),
    }
  }, [navigate, ws])
}
