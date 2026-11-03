import { Copy, ExternalLink, Folder as FolderIcon, FolderInput, PenTool, Trash2 } from 'lucide-react'
import { Link, useNavigate } from 'react-router'
import type { Drawing, Folder } from '@/data'
import { untitled } from '@/lib/entities'
import { paths } from '@/lib/routes'
import { formatRelative } from '@/lib/utils'
import { openContextMenu, type MenuItem } from '@/stores/menuStore'
import { useCan } from '@/stores/permissions'
import { deleteDrawing, duplicateDrawing, updateDrawing } from './drawingActions'

export function useDrawingMenu() {
  const navigate = useNavigate()
  const canEdit = useCan('content.edit')
  return (drawing: Drawing, folders: Folder[] = []): MenuItem[] => {
    const open: MenuItem = { label: 'Open', icon: ExternalLink, onSelect: () => navigate(paths.drawing(drawing.workspaceId, drawing.id)) }
    if (!canEdit) return [open]
    return [
      open,
      {
        label: 'Duplicate',
        icon: Copy,
        onSelect: async () => {
          const copy = await duplicateDrawing(drawing)
          if (copy) navigate(paths.drawing(copy.workspaceId, copy.id))
        },
      },
      ...(folders.length || drawing.folderId
        ? ([
            { type: 'label', label: 'Move to' },
            ...(drawing.folderId ? [{ label: 'No folder', icon: FolderInput, onSelect: () => void updateDrawing(drawing.id, { folderId: null }) }] : []),
            ...folders
              .filter((f) => f.id !== drawing.folderId)
              .map<MenuItem>((f) => ({ label: f.name, icon: FolderIcon, onSelect: () => void updateDrawing(drawing.id, { folderId: f.id }) })),
          ] as MenuItem[])
        : []),
      { type: 'separator' },
      { label: 'Delete', icon: Trash2, danger: true, onSelect: () => void deleteDrawing(drawing) },
    ]
  }
}

export function DrawingCard({ drawing, menu }: { drawing: Drawing; menu: MenuItem[] }) {
  return (
    <Link
      to={paths.drawing(drawing.workspaceId, drawing.id)}
      onContextMenu={(e) => openContextMenu(e, menu)}
      className="group flex flex-col overflow-hidden rounded-xl border border-line bg-surface transition-[border-color,box-shadow] hover:border-line-strong hover:shadow-md hover:shadow-black/5"
    >
      <div className="flex aspect-[16/10] items-center justify-center overflow-hidden border-b border-line bg-[radial-gradient(var(--ds-line)_1px,transparent_1px)] [background-size:14px_14px]">
        {drawing.thumbnail ? (
          <img src={drawing.thumbnail} alt="" className="max-h-full max-w-full object-contain p-3 dark:invert dark:hue-rotate-180" draggable={false} />
        ) : (
          <PenTool className="size-6 text-fg-subtle" />
        )}
      </div>
      <div className="px-3 py-2.5">
        <h3 className="truncate text-sm font-medium">{untitled(drawing.title)}</h3>
        <p className="mt-0.5 text-xs text-fg-subtle">Edited {formatRelative(drawing.updatedAt)}</p>
      </div>
    </Link>
  )
}
