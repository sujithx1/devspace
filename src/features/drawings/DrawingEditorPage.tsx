import { ArrowLeft, Copy, FileImage, FileCode2, Folder as FolderIcon, FolderInput, MoreHorizontal, PenTool, Trash2 } from 'lucide-react'
import { lazy, Suspense, useEffect, useMemo, useRef, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import { ProjectSelect } from '@/components/shared/ProjectSelect'
import { SaveIndicator, type SaveState } from '@/components/shared/SaveIndicator'
import { Button } from '@/components/ui/Button'
import { EmptyState, Spinner } from '@/components/ui/States'
import type { Drawing, DrawingInput } from '@/data'
import { trackVisit } from '@/features/dashboard/useRecentEntries'
import { paths } from '@/lib/routes'
import { debounce, downloadBlob, slugify } from '@/lib/utils'
import { useDrawingsStore, useFoldersStore } from '@/stores/collections'
import { openDropdownMenu, type MenuItem } from '@/stores/menuStore'
import { toast } from '@/stores/toastStore'
import { useCan } from '@/stores/permissions'
import { useUIStore } from '@/stores/uiStore'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { deleteDrawing, duplicateDrawing, updateDrawing } from './drawingActions'
import type { SceneChange, WhiteboardHandle } from './WhiteboardCanvas'

// The drawing engine is large; load it only when a drawing is opened.
const WhiteboardCanvas = lazy(() => import('./WhiteboardCanvas'))

export function DrawingEditorPage() {
  const { drawingId = '' } = useParams()
  const ws = useWorkspaceId()
  const status = useDrawingsStore((s) => s.status)
  const drawing = useDrawingsStore((s) => s.items.find((d) => d.id === drawingId))
  const exists = !!drawing

  useEffect(() => {
    if (exists) trackVisit(ws, 'drawing', drawingId)
  }, [exists, ws, drawingId])

  if (status !== 'ready') {
    return (
      <div className="flex flex-1 items-center justify-center">
        <Spinner />
      </div>
    )
  }
  if (!drawing) {
    return (
      <div className="flex flex-1 items-center justify-center">
        <EmptyState
          icon={PenTool}
          title="Drawing not found"
          description="It may have been deleted."
          action={
            <Link to={paths.drawings(ws)} className="text-sm font-medium text-accent hover:underline">
              Back to drawings
            </Link>
          }
        />
      </div>
    )
  }
  return <DrawingEditor key={drawing.id} drawing={drawing} />
}

function DrawingEditor({ drawing }: { drawing: Drawing }) {
  const ws = useWorkspaceId()
  const navigate = useNavigate()
  const theme = useUIStore((s) => s.resolvedTheme)
  const allFolders = useFoldersStore((s) => s.items)
  const folders = useMemo(() => allFolders.filter((f) => f.kind === 'drawing'), [allFolders])
  const canvasRef = useRef<WhiteboardHandle>(null)
  const [title, setTitle] = useState(drawing.title)
  const canEdit = useCan('content.edit')
  const [saveState, setSaveState] = useState<SaveState>('saved')
  const pending = useRef<Partial<DrawingInput>>({})
  const needsThumbnail = useRef(false)

  const save = useMemo(
    () =>
      debounce(async () => {
        const patch = pending.current
        pending.current = {}
        setSaveState('saving')
        try {
          if (needsThumbnail.current) {
            needsThumbnail.current = false
            patch.thumbnail = (await canvasRef.current?.thumbnail().catch(() => null)) ?? null
          }
          await useDrawingsStore.getState().update(drawing.id, patch)
          setSaveState(Object.keys(pending.current).length ? 'pending' : 'saved')
        } catch (error) {
          pending.current = { ...patch, ...pending.current }
          setSaveState('error')
          toast.error(error, 'Could not save drawing')
        }
      }, 800),
    [drawing.id],
  )

  useEffect(() => {
    const flush = () => save.flush()
    window.addEventListener('pagehide', flush)
    return () => {
      window.removeEventListener('pagehide', flush)
      save.flush()
    }
  }, [save])

  const queue = (patch: Partial<DrawingInput>) => {
    pending.current = { ...pending.current, ...patch }
    setSaveState('pending')
    save()
  }

  const onSceneChange = ({ scene, contentChanged }: SceneChange) => {
    // Viewers can pan and zoom, but nothing is saved.
    if (!canEdit) return
    if (contentChanged) needsThumbnail.current = true
    queue({ scene })
  }

  const exportAs = async (format: 'png' | 'svg') => {
    try {
      const blob = format === 'png' ? await canvasRef.current!.exportPng() : await canvasRef.current!.exportSvg()
      downloadBlob(blob, `${slugify(title, 'drawing')}.${format}`)
      toast.success(`Exported ${format.toUpperCase()}`)
    } catch (error) {
      toast.error(error, 'Export failed')
    }
  }

  const openMenu = (e: React.MouseEvent<HTMLButtonElement>) => {
    const exportItems: MenuItem[] = [
      { label: 'Export as PNG', icon: FileImage, onSelect: () => void exportAs('png') },
      { label: 'Export as SVG', icon: FileCode2, onSelect: () => void exportAs('svg') },
    ]
    if (!canEdit) return openDropdownMenu(e, exportItems)
    const items: MenuItem[] = [
      ...exportItems,
      {
        label: 'Duplicate',
        icon: Copy,
        onSelect: async () => {
          save.flush()
          const latest = useDrawingsStore.getState().items.find((d) => d.id === drawing.id) ?? drawing
          const copy = await duplicateDrawing({ ...latest, ...(pending.current as Partial<Drawing>) })
          if (copy) navigate(paths.drawing(ws, copy.id))
        },
      },
    ]
    if (folders.length || drawing.folderId) {
      items.push({ type: 'label', label: 'Move to folder' })
      if (drawing.folderId) items.push({ label: 'No folder', icon: FolderInput, onSelect: () => void updateDrawing(drawing.id, { folderId: null }) })
      for (const f of folders) if (f.id !== drawing.folderId) items.push({ label: f.name, icon: FolderIcon, onSelect: () => void updateDrawing(drawing.id, { folderId: f.id }) })
    }
    items.push({ type: 'separator' })
    items.push({
      label: 'Delete drawing',
      icon: Trash2,
      danger: true,
      onSelect: async () => {
        save.cancel()
        if (await deleteDrawing(drawing)) navigate(paths.drawings(ws))
      },
    })
    openDropdownMenu(e, items)
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <header className="flex h-13 shrink-0 items-center gap-2 border-b border-line bg-surface px-3 md:px-4">
        <Link to={paths.drawings(ws)} aria-label="Back to drawings" title="Back to drawings" className="flex size-8 items-center justify-center rounded-md text-fg-muted hover:bg-surface-2 hover:text-fg">
          <ArrowLeft className="size-4" />
        </Link>
        <label className="min-w-0 flex-1">
          <span className="sr-only">Drawing title</span>
          <input
            value={title}
            readOnly={!canEdit}
            maxLength={200}
            placeholder="Untitled drawing"
            onChange={(e) => {
              setTitle(e.target.value)
              queue({ title: e.target.value })
            }}
            className="w-full max-w-md truncate rounded-md bg-transparent px-2 py-1 text-sm font-semibold outline-none placeholder:text-fg-subtle hover:bg-surface-2 focus:bg-surface-2"
          />
        </label>
        {canEdit && <SaveIndicator state={saveState} className="hidden lg:flex" />}
        <ProjectSelect compact disabled={!canEdit} value={drawing.projectId} onChange={(projectId) => void updateDrawing(drawing.id, { projectId })} className="hidden md:inline-flex" />
        <Button size="sm" variant="outline" onClick={() => void exportAs('png')} className="hidden sm:inline-flex">
          <FileImage className="size-3.5" /> PNG
        </Button>
        <Button size="sm" variant="outline" onClick={() => void exportAs('svg')} className="hidden sm:inline-flex">
          <FileCode2 className="size-3.5" /> SVG
        </Button>
        <Button size="icon-sm" variant="ghost" aria-label="More actions" aria-haspopup="menu" onClick={openMenu}>
          <MoreHorizontal className="size-4" />
        </Button>
      </header>
      <div className="relative min-h-0 flex-1">
        <Suspense
          fallback={
            <div className="flex h-full items-center justify-center gap-2 text-sm text-fg-muted">
              <Spinner className="size-4" /> Loading whiteboard…
            </div>
          }
        >
          <WhiteboardCanvas ref={canvasRef} initialScene={drawing.scene} theme={theme} readOnly={!canEdit} onChange={onSceneChange} />
        </Suspense>
      </div>
    </div>
  )
}

