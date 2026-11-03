import { NodeViewContent, NodeViewWrapper, type ReactNodeViewProps } from '@tiptap/react'
import { Check, Copy } from 'lucide-react'
import { useState } from 'react'
import { CODE_LANGUAGES } from './lowlight'

/** Code block with a language picker and copy button. */
export function CodeBlockView({ node, updateAttributes, editor }: ReactNodeViewProps) {
  const [copied, setCopied] = useState(false)
  const language = (node.attrs.language as string | null) ?? ''

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(node.textContent)
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    } catch {
      // Clipboard can be unavailable (e.g. insecure context); nothing to recover.
    }
  }

  return (
    <NodeViewWrapper className="group relative">
      <div contentEditable={false} className="absolute top-2 right-2 z-10 flex items-center gap-1 opacity-60 transition-opacity group-hover:opacity-100 focus-within:opacity-100">
        <select
          aria-label="Code language"
          value={language}
          disabled={!editor.isEditable}
          onChange={(e) => updateAttributes({ language: e.target.value || null })}
          className="h-6 cursor-pointer rounded border border-line bg-surface px-1 font-sans text-[11px] text-fg-muted outline-none"
        >
          <option value="">Auto</option>
          {CODE_LANGUAGES.map((l) => (
            <option key={l.id} value={l.id}>
              {l.label}
            </option>
          ))}
        </select>
        <button
          type="button"
          onClick={copy}
          aria-label="Copy code"
          className="flex size-6 items-center justify-center rounded border border-line bg-surface text-fg-muted hover:text-fg"
        >
          {copied ? <Check className="size-3 text-success" /> : <Copy className="size-3" />}
        </button>
      </div>
      <pre spellCheck={false} className="pt-10!">
        <NodeViewContent<'code'> as="code" className={language ? `language-${language}` : undefined} />
      </pre>
    </NodeViewWrapper>
  )
}
