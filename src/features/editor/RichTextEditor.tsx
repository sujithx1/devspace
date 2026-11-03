import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight'
import Image from '@tiptap/extension-image'
import { Placeholder } from '@tiptap/extension-placeholder'
import { TaskItem } from '@tiptap/extension-task-item'
import { TaskList } from '@tiptap/extension-task-list'
import { EditorContent, ReactNodeViewRenderer, useEditor, useEditorState, type Editor, type JSONContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import {
  Bold,
  Code,
  Heading1,
  Heading2,
  Heading3,
  ImagePlus,
  Italic,
  Link2,
  List,
  ListChecks,
  ListOrdered,
  Minus,
  Quote,
  Redo2,
  SquareCode,
  Strikethrough,
  Undo2,
  type LucideIcon,
} from 'lucide-react'
import { useEffect, useLayoutEffect, useRef } from 'react'
import type { RichContent } from '@/data'
import { cn, modKey } from '@/lib/utils'
import { promptDialog } from '@/stores/dialogStore'
import { openDropdownMenu } from '@/stores/menuStore'
import { toast } from '@/stores/toastStore'
import { CodeBlockView } from './CodeBlockView'
import { isValidUrl, normalizeUrl, readImageFile } from './images'
import { lowlight } from './lowlight'

export interface EditorChange {
  content: RichContent
  plainText: string
}

interface Props {
  initialContent: RichContent | null
  placeholder?: string
  onChange: (change: EditorChange) => void
  /** Called once the editor instance exists (e.g. to focus it). */
  onReady?: (editor: Editor) => void
  /** Read-only mode hides the toolbar and blocks edits. */
  editable?: boolean
  className?: string
}

async function promptForLink(editor: Editor) {
  const previous = (editor.getAttributes('link').href as string | undefined) ?? ''
  const value = await promptDialog({
    title: previous ? 'Edit link' : 'Insert link',
    label: 'URL',
    initialValue: previous,
    placeholder: 'https://example.com',
    confirmLabel: 'Apply',
    validate: (v) => (isValidUrl(normalizeUrl(v)) ? null : 'Enter a valid http(s) or mailto URL'),
  })
  if (value === null) return editor.commands.focus()
  const href = normalizeUrl(value)
  const chain = editor.chain().focus().extendMarkRange('link')
  if (editor.state.selection.empty && !previous) {
    chain.insertContent({ type: 'text', text: href, marks: [{ type: 'link', attrs: { href } }] }).run()
  } else {
    chain.setLink({ href }).run()
  }
}

async function insertImageFiles(editor: Editor, files: File[], pos?: number) {
  for (const file of files) {
    try {
      const src = await readImageFile(file)
      const node = { type: 'image', attrs: { src, alt: file.name } }
      if (pos !== undefined) editor.chain().focus().insertContentAt(pos, node).run()
      else editor.chain().focus().setImage({ src, alt: file.name }).run()
    } catch (error) {
      toast.error(error)
    }
  }
}

export function RichTextEditor({ initialContent, placeholder, onChange, onReady, editable = true, className }: Props) {
  const onChangeRef = useRef(onChange)
  const onReadyRef = useRef(onReady)
  useLayoutEffect(() => {
    onChangeRef.current = onChange
    onReadyRef.current = onReady
  })
  const fileInput = useRef<HTMLInputElement>(null)
  const editorRef = useRef<Editor | null>(null)

  const editor = useEditor({
    immediatelyRender: true,
    editable,
    shouldRerenderOnTransaction: false,
    extensions: [
      StarterKit.configure({
        heading: { levels: [1, 2, 3] },
        codeBlock: false,
        link: { openOnClick: false, autolink: true, defaultProtocol: 'https' },
      }),
      CodeBlockLowlight.extend({
        addNodeView() {
          return ReactNodeViewRenderer(CodeBlockView)
        },
      }).configure({ lowlight, defaultLanguage: null }),
      TaskList,
      TaskItem.configure({ nested: true }),
      Image.configure({ allowBase64: true }),
      Placeholder.configure({ placeholder: placeholder ?? 'Start writing…' }),
    ],
    content: (initialContent as JSONContent | null) ?? '',
    editorProps: {
      attributes: { class: 'prose-editor min-h-[50vh] pb-32', 'aria-label': 'Document body', role: 'textbox', 'aria-multiline': 'true' },
      handleKeyDown: (_view, event) => {
        if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
          event.preventDefault()
          if (editorRef.current) void promptForLink(editorRef.current)
          return true
        }
        return false
      },
      handlePaste: (_view, event) => {
        const files = Array.from(event.clipboardData?.files ?? []).filter((f) => f.type.startsWith('image/'))
        if (files.length === 0) return false
        if (editorRef.current) void insertImageFiles(editorRef.current, files)
        return true
      },
      handleDrop: (view, event) => {
        const files = Array.from(event.dataTransfer?.files ?? []).filter((f) => f.type.startsWith('image/'))
        if (files.length === 0) return false
        event.preventDefault()
        const pos = view.posAtCoords({ left: event.clientX, top: event.clientY })?.pos
        if (editorRef.current) void insertImageFiles(editorRef.current, files, pos)
        return true
      },
    },
    onUpdate: ({ editor }) => {
      onChangeRef.current({ content: editor.getJSON() as RichContent, plainText: editor.getText({ blockSeparator: '\n' }) })
    },
  })

  useEffect(() => {
    editorRef.current = editor
    if (editor) onReadyRef.current?.(editor)
    // Only on mount of a given editor instance.
  }, [editor])

  useEffect(() => {
    if (editor && editor.isEditable !== editable) editor.setEditable(editable)
  }, [editor, editable])

  return (
    <div className={cn('flex flex-col', className)}>
      {editable && <Toolbar editor={editor} onPickImage={() => fileInput.current?.click()} />}
      <EditorContent editor={editor} className="mt-4" />
      <input
        ref={fileInput}
        type="file"
        accept="image/*"
        multiple
        hidden
        onChange={(e) => {
          const files = Array.from(e.target.files ?? [])
          e.target.value = ''
          void insertImageFiles(editor, files)
        }}
      />
    </div>
  )
}

interface ToolButton {
  label: string
  icon: LucideIcon
  shortcut?: string
  active?: boolean
  disabled?: boolean
  run: () => void
}

function Toolbar({ editor, onPickImage }: { editor: Editor; onPickImage: () => void }) {
  const state = useEditorState({
    editor,
    selector: ({ editor: e }) => ({
      bold: e.isActive('bold'),
      italic: e.isActive('italic'),
      strike: e.isActive('strike'),
      code: e.isActive('code'),
      h1: e.isActive('heading', { level: 1 }),
      h2: e.isActive('heading', { level: 2 }),
      h3: e.isActive('heading', { level: 3 }),
      bullet: e.isActive('bulletList'),
      ordered: e.isActive('orderedList'),
      task: e.isActive('taskList'),
      quote: e.isActive('blockquote'),
      codeBlock: e.isActive('codeBlock'),
      link: e.isActive('link'),
      canUndo: e.can().undo(),
      canRedo: e.can().redo(),
    }),
  })

  const chain = () => editor.chain().focus()
  const groups: ToolButton[][] = [
    [
      { label: 'Undo', icon: Undo2, shortcut: `${modKey}Z`, disabled: !state.canUndo, run: () => chain().undo().run() },
      { label: 'Redo', icon: Redo2, shortcut: `${modKey}⇧Z`, disabled: !state.canRedo, run: () => chain().redo().run() },
    ],
    [
      { label: 'Heading 1', icon: Heading1, active: state.h1, run: () => chain().toggleHeading({ level: 1 }).run() },
      { label: 'Heading 2', icon: Heading2, active: state.h2, run: () => chain().toggleHeading({ level: 2 }).run() },
      { label: 'Heading 3', icon: Heading3, active: state.h3, run: () => chain().toggleHeading({ level: 3 }).run() },
    ],
    [
      { label: 'Bold', icon: Bold, shortcut: `${modKey}B`, active: state.bold, run: () => chain().toggleBold().run() },
      { label: 'Italic', icon: Italic, shortcut: `${modKey}I`, active: state.italic, run: () => chain().toggleItalic().run() },
      { label: 'Strikethrough', icon: Strikethrough, active: state.strike, run: () => chain().toggleStrike().run() },
      { label: 'Inline code', icon: Code, shortcut: `${modKey}E`, active: state.code, run: () => chain().toggleCode().run() },
      { label: 'Link', icon: Link2, shortcut: `${modKey}K`, active: state.link, run: () => void promptForLink(editor) },
    ],
    [
      { label: 'Bulleted list', icon: List, active: state.bullet, run: () => chain().toggleBulletList().run() },
      { label: 'Numbered list', icon: ListOrdered, active: state.ordered, run: () => chain().toggleOrderedList().run() },
      { label: 'Checklist', icon: ListChecks, active: state.task, run: () => chain().toggleTaskList().run() },
      { label: 'Quote', icon: Quote, active: state.quote, run: () => chain().toggleBlockquote().run() },
      { label: 'Code block', icon: SquareCode, shortcut: `${modKey}⌥C`, active: state.codeBlock, run: () => chain().toggleCodeBlock().run() },
      { label: 'Divider', icon: Minus, run: () => chain().setHorizontalRule().run() },
    ],
  ]

  const openImageMenu = (e: React.MouseEvent<HTMLButtonElement>) =>
    openDropdownMenu(e, [
      { label: 'Upload image…', icon: ImagePlus, onSelect: onPickImage },
      {
        label: 'Image from URL…',
        icon: Link2,
        onSelect: async () => {
          const value = await promptDialog({
            title: 'Insert image',
            label: 'Image URL',
            placeholder: 'https://…/diagram.png',
            confirmLabel: 'Insert',
            validate: (v) => (isValidUrl(normalizeUrl(v), ['http:', 'https:']) ? null : 'Enter a valid image URL'),
          })
          if (value) chain().setImage({ src: normalizeUrl(value) }).run()
        },
      },
    ])

  return (
    <div
      role="toolbar"
      aria-label="Formatting"
      className="sticky top-0 z-10 -mx-2 flex flex-wrap items-center gap-0.5 rounded-lg border border-line bg-surface/95 px-1.5 py-1 backdrop-blur"
    >
      {groups.map((group, gi) => (
        <div key={gi} className="flex items-center gap-0.5">
          {gi > 0 && <span className="mx-1 h-5 w-px bg-line" aria-hidden="true" />}
          {group.map((b) => (
            <ToolbarButton key={b.label} {...b} />
          ))}
        </div>
      ))}
      <span className="mx-1 h-5 w-px bg-line" aria-hidden="true" />
      <button
        type="button"
        onClick={openImageMenu}
        aria-label="Insert image"
        title="Insert image"
        aria-haspopup="menu"
        className="flex size-7 items-center justify-center rounded-md text-fg-muted hover:bg-surface-2 hover:text-fg"
      >
        <ImagePlus className="size-4" />
      </button>
    </div>
  )
}

function ToolbarButton({ label, icon: Icon, shortcut, active, disabled, run }: ToolButton) {
  return (
    <button
      type="button"
      onMouseDown={(e) => e.preventDefault()}
      onClick={run}
      disabled={disabled}
      aria-label={label}
      aria-pressed={active}
      title={shortcut ? `${label} (${shortcut})` : label}
      className={cn(
        'flex size-7 items-center justify-center rounded-md transition-colors disabled:opacity-35',
        active ? 'bg-accent-soft text-accent' : 'text-fg-muted hover:bg-surface-2 hover:text-fg',
      )}
    >
      <Icon className="size-4" />
    </button>
  )
}
