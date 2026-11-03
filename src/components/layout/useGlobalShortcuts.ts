import { useEffect } from 'react'
import { useNavigate } from 'react-router'
import { useCreateActions } from '@/features/useCreateActions'
import { paths } from '@/lib/routes'
import { useDialogStore } from '@/stores/dialogStore'
import { useQuickCreateStore } from '@/stores/quickCreateStore'
import { useUIStore } from '@/stores/uiStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'

function isTypingTarget(target: EventTarget | null) {
  const el = target as HTMLElement | null
  if (!el) return false
  return el.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(el.tagName) || !!el.closest('.excalidraw')
}

function anyModalOpen() {
  const { commandPaletteOpen, shortcutsOpen } = useUIStore.getState()
  const { task, project } = useQuickCreateStore.getState()
  return commandPaletteOpen || shortcutsOpen || task.open || project.open || !!useDialogStore.getState().current
}

export function useGlobalShortcuts() {
  const navigate = useNavigate()
  const create = useCreateActions()

  useEffect(() => {
    let pendingG = 0

    const onKeyDown = (e: KeyboardEvent) => {
      const ui = useUIStore.getState()
      const mod = e.metaKey || e.ctrlKey
      const ws = useWorkspaceStore.getState().activeId

      if (mod && e.key.toLowerCase() === 'k' && !e.shiftKey && !e.altKey) {
        // Inside the rich-text editor ⌘K inserts a link instead.
        if ((e.target as HTMLElement | null)?.closest?.('.ProseMirror')) return
        e.preventDefault()
        ui.setCommandPaletteOpen(!ui.commandPaletteOpen)
        return
      }
      if (mod && e.key === '\\') {
        e.preventDefault()
        ui.toggleSidebar()
        return
      }
      if (mod && e.shiftKey && e.code === 'KeyL') {
        e.preventDefault()
        ui.cycleTheme()
        return
      }

      if (isTypingTarget(e.target) || anyModalOpen() || !ws) return

      if (e.altKey && !mod) {
        const actions: Record<string, () => void> = {
          KeyN: () => void create.newNote(),
          KeyT: () => create.newTask(),
          KeyP: () => create.newProject(),
          KeyD: () => void create.newDoc(),
          KeyW: () => void create.newDrawing(),
        }
        const action = actions[e.code]
        if (action) {
          e.preventDefault()
          action()
        }
        return
      }
      if (mod) return

      if (e.key === '?') {
        e.preventDefault()
        ui.setShortcutsOpen(true)
        return
      }

      if (Date.now() - pendingG < 1200) {
        pendingG = 0
        const targets: Record<string, string> = {
          h: paths.workspace(ws),
          n: paths.notes(ws),
          t: paths.tasks(ws),
          p: paths.projects(ws),
          d: paths.docs(ws),
          w: paths.drawings(ws),
          s: paths.settings(ws),
        }
        const to = targets[e.key.toLowerCase()]
        if (to) {
          e.preventDefault()
          navigate(to)
        }
        return
      }
      if (e.key.toLowerCase() === 'g') pendingG = Date.now()
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [navigate, create])
}
