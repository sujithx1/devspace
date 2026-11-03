import type { Editor } from '@tiptap/react'
import { ArrowLeft, Copy, Download, Folder as FolderIcon, FolderInput, MoreHorizontal, Pin, Trash2 } from 'lucide-react'
import { useEffect, useMemo, useRef, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import { ProjectSelect } from '@/components/shared/ProjectSelect'
import { SaveIndicator, type SaveState } from '@/components/shared/SaveIndicator'
import { TagInput } from '@/components/shared/TagInput'
import { Button } from '@/components/ui/Button'
import { EmptyState, Spinner } from '@/components/ui/States'
import type { Page, PageInput } from '@/data'
import { trackVisit } from '@/features/dashboard/useRecentEntries'
import { RichTextEditor, type EditorChange } from '@/features/editor/RichTextEditor'
import { toMarkdown, type JSONNode } from '@/features/editor/markdown'
import { untitled } from '@/lib/entities'
import { cn, debounce, downloadBlob, formatRelative, pluralize, slugify } from '@/lib/utils'
import { useFoldersStore } from '@/stores/collections'
import { openDropdownMenu, type MenuItem } from '@/stores/menuStore'
import { toast } from '@/stores/toastStore'
import { useCan } from '@/stores/permissions'
import { useWorkspaceId } from '@/stores/workspaceStore'
import { deletePage, duplicatePage, updatePage } from './pageActions'
import { PAGE_KINDS, type PageKind } from './pageKinds'

export function PageEditorRoute({ kind }: { kind: PageKind }) {
  const config = PAGE_KINDS[kind]
  const { pageId = '' } = useParams()
  const ws = useWorkspaceId()
  const status = config.useStore((s) => s.status)
  const page = config.useStore((s) => s.items.find((p) => p.id === pageId))
  const exists = !!page

  useEffect(() => {
    if (exists) trackVisit(ws, kind, pageId)
  }, [exists, ws, kind, pageId])

  if (status !== 'ready') {
    return (
      <div className="flex flex-1 items-center justify-center">
        <Spinner />
      </div>
    )
  }
  if (!page) {
    return (
      <div className="flex flex-1 items-center justify-center">
        <EmptyState
          icon={config.icon}
          title={`${config.label} not found`}
          description="It may have been deleted."
          action={
            <Link to={config.listPath(ws)} className="text-sm font-medium text-accent hover:underline">
              Back to {config.plural.toLowerCase()}
            </Link>
          }
        />
      </div>
    )
  }
  return <PageEditor key={page.id} kind={kind} page={page} />
}

function PageEditor({ kind, page }: { kind: PageKind; page: Page }) {
  const config = PAGE_KINDS[kind]
  const ws = useWorkspaceId()
  const navigate = useNavigate()
  const folders = useFoldersStore((s) => s.items)
  const folder = folders.find((f) => f.id === page.folderId)
  const [title, setTitle] = useState(page.title)
  const canEdit = useCan('content.edit')
  const [saveState, setSaveState] = useState<SaveState>('saved')
  const [wordCount, setWordCount] = useState(() => countWords(page.plainText))
  const editorRef = useRef<Editor | null>(null)
  const pending = useRef<Partial<PageInput>>({})

  // Debounced autosave of title/body edits. Other fields save immediately.
  const save = useMemo(
    () =>
      debounce(async () => {
        const patch = pending.current
        pending.current = {}
        setSaveState('saving')
        const ok = await updatePage(kind, page.id, patch)
        // Keep failed edits queued so the next change retries them.
        if (!ok) pending.current = { ...patch, ...pending.current }
        setSaveState(!ok ? 'error' : Object.keys(pending.current).length ? 'pending' : 'saved')
      }, 600),
    [kind, page.id],
  )

  useEffect(() => {
    const flush = () => save.flush()
    window.addEventListener('pagehide', flush)
    return () => {
      window.removeEventListener('pagehide', flush)
      save.flush()
    }
  }, [save])

  const queue = (patch: Partial<PageInput>) => {
    pending.current = { ...pending.current, ...patch }
    setSaveState('pending')
    save()
  }

  const onBodyChange = ({ content, plainText }: EditorChange) => {
    setWordCount(countWords(plainText))
    queue({ content, plainText })
  }

  const exportMarkdown = () => {
    const json = (editorRef.current?.getJSON() ?? page.content) as JSONNode | null
    const md = toMarkdown(json, title.trim() || undefined)
    downloadBlob(new Blob([md], { type: 'text/markdown;charset=utf-8' }), `${slugify(title)}.md`)
    toast.success('Exported as Markdown')
  }

  const copyMarkdown = async () => {
    try {
      const json = (editorRef.current?.getJSON() ?? page.content) as JSONNode | null
      await navigator.clipboard.writeText(toMarkdown(json, title.trim() || undefined))
      toast.success('Markdown copied to clipboard')
    } catch (error) {
      toast.error(error, 'Clipboard is unavailable')
    }
  }

  const sameKindFolders = folders.filter((f) => f.kind === config.folderKind)
  const openMenu = (e: React.MouseEvent<HTMLButtonElement>) => {
    const exportItems: MenuItem[] = [
      { label: 'Export as Markdown', icon: Download, onSelect: exportMarkdown },
      { label: 'Copy as Markdown', icon: Copy, onSelect: () => void copyMarkdown() },
    ]
    if (!canEdit) return openDropdownMenu(e, exportItems)
    const items: MenuItem[] = [
      {
        label: 'Duplicate',
        icon: Copy,
        onSelect: async () => {
          save.flush()
          const copy = await duplicatePage(kind, { ...page, title, ...pending.current } as Page)
          if (copy) navigate(config.itemPath(ws, copy.id))
        },
      },
      ...exportItems,
    ]
    if (sameKindFolders.length || page.folderId) {
      items.push({ type: 'label', label: 'Move to folder' })
      if (page.folderId) items.push({ label: 'No folder', icon: FolderInput, onSelect: () => void updatePage(kind, page.id, { folderId: null }) })
      for (const f of sameKindFolders) {
        if (f.id !== page.folderId) items.push({ label: f.name, icon: FolderIcon, onSelect: () => void updatePage(kind, page.id, { folderId: f.id }) })
      }
    }
    items.push({ type: 'separator' })
    items.push({
      label: `Delete ${config.label.toLowerCase()}`,
      icon: Trash2,
      danger: true,
      onSelect: async () => {
        save.cancel()
        if (await deletePage(kind, page)) navigate(config.listPath(ws))
      },
    })
    openDropdownMenu(e, items)
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <header className="flex h-13 shrink-0 items-center gap-2 border-b border-line bg-surface/80 px-3 backdrop-blur md:px-5">
        <Link to={config.listPath(ws)} aria-label={`Back to ${config.plural.toLowerCase()}`} className="flex size-8 items-center justify-center rounded-md text-fg-muted hover:bg-surface-2 md:hidden">
          <ArrowLeft className="size-4" />
        </Link>
        <nav aria-label="Breadcrumb" className="flex min-w-0 flex-1 items-center gap-1.5 text-sm text-fg-muted">
          <Link to={config.listPath(ws)} className="hidden hover:text-fg sm:inline">
            {config.plural}
          </Link>
          {folder && (
            <>
              <span className="hidden text-fg-subtle sm:inline">/</span>
              <span className="hidden items-center gap-1 sm:flex">
                <FolderIcon className="size-3.5" />
                {folder.name}
              </span>
            </>
          )}
          <span className="hidden text-fg-subtle sm:inline">/</span>
          <span className="truncate font-medium text-fg">{untitled(title)}</span>
        </nav>
        {canEdit && <SaveIndicator state={saveState} className="hidden sm:flex" />}
        <ProjectSelect compact disabled={!canEdit} value={page.projectId} onChange={(projectId) => void updatePage(kind, page.id, { projectId })} className="hidden sm:inline-flex" />
        {canEdit && (
          <Button
            size="icon-sm"
            variant="ghost"
            aria-label={page.pinned ? 'Unpin' : 'Pin to sidebar'}
            aria-pressed={page.pinned}
            title={page.pinned ? 'Unpin' : 'Pin to sidebar'}
            onClick={() => void updatePage(kind, page.id, { pinned: !page.pinned })}
            className={cn(page.pinned && 'text-accent')}
          >
            <Pin className={cn('size-4', page.pinned && 'fill-current')} />
          </Button>
        )}
        <Button size="icon-sm" variant="ghost" aria-label="More actions" aria-haspopup="menu" title="More actions" onClick={openMenu}>
          <MoreHorizontal className="size-4" />
        </Button>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto">
        <article className="mx-auto w-full max-w-3xl px-5 pt-10 md:px-10">
          <TitleInput
            value={title}
            readOnly={!canEdit}
            placeholder={`Untitled ${config.label.toLowerCase()}`}
            onChange={(value) => {
              setTitle(value)
              queue({ title: value })
            }}
            onEnter={() => {
              const editor = editorRef.current
              if (!editor) return
              // Focus synchronously; Tiptap's focus command defers to the next animation frame.
              editor.view.focus()
              editor.commands.focus('start')
            }}
          />
          <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-2 border-b border-line pb-4 text-xs text-fg-subtle">
            <TagInput tags={page.tags} readOnly={!canEdit} onChange={(tags) => void updatePage(kind, page.id, { tags })} />
            <span className="ml-auto">
              {pluralize(wordCount, 'word')} · Edited {formatRelative(page.updatedAt)}
            </span>
            <ProjectSelect compact disabled={!canEdit} value={page.projectId} onChange={(projectId) => void updatePage(kind, page.id, { projectId })} className="sm:hidden" />
          </div>
          <RichTextEditor
            className="mt-4"
            initialContent={page.content}
            placeholder={config.placeholder}
            onChange={onBodyChange}
            editable={canEdit}
            onReady={(editor) => {
              editorRef.current = editor
              if (canEdit && !page.title && !page.plainText) requestAnimationFrame(() => document.getElementById('page-title')?.focus())
            }}
          />
        </article>
      </div>
    </div>
  )
}

function TitleInput({
  value,
  placeholder,
  readOnly,
  onChange,
  onEnter,
}: {
  value: string
  placeholder: string
  readOnly?: boolean
  onChange: (v: string) => void
  onEnter: () => void
}) {
  const ref = useRef<HTMLTextAreaElement>(null)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    el.style.height = 'auto'
    el.style.height = `${el.scrollHeight}px`
  }, [value])
  return (
    <textarea
      id="page-title"
      ref={ref}
      rows={1}
      value={value}
      readOnly={readOnly}
      maxLength={200}
      aria-label="Title"
      placeholder={placeholder}
      onChange={(e) => onChange(e.target.value.replace(/\n/g, ''))}
      onKeyDown={(e) => {
        if (e.key === 'Enter') {
          e.preventDefault()
          onEnter()
        }
      }}
      className="w-full resize-none overflow-hidden bg-transparent text-3xl leading-tight font-bold tracking-tight outline-none placeholder:text-fg-subtle"
    />
  )
}

function countWords(text: string) {
  return text.trim() ? text.trim().split(/\s+/).length : 0
}
