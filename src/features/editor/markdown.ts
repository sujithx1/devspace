/**
 * Minimal Tiptap JSON → Markdown serializer for exporting notes and docs.
 * Covers the node and mark types our editor produces.
 */

export interface JSONNode {
  type?: string
  attrs?: Record<string, unknown>
  content?: JSONNode[]
  text?: string
  marks?: { type: string; attrs?: Record<string, unknown> }[]
}

function inline(nodes: JSONNode[] = []): string {
  return nodes
    .map((node) => {
      if (node.type === 'hardBreak') return '  \n'
      if (node.type === 'image') return `![${String(node.attrs?.alt ?? '')}](${String(node.attrs?.src ?? '')})`
      let text = node.text ?? ''
      const marks = node.marks ?? []
      const isCode = marks.some((m) => m.type === 'code')
      if (!isCode) text = text.replace(/([\\`*_[\]])/g, '\\$1')
      for (const mark of marks) {
        if (mark.type === 'code') text = `\`${text}\``
        else if (mark.type === 'bold') text = `**${text}**`
        else if (mark.type === 'italic') text = `*${text}*`
        else if (mark.type === 'strike') text = `~~${text}~~`
      }
      const link = marks.find((m) => m.type === 'link')
      if (link) text = `[${text}](${String(link.attrs?.href ?? '')})`
      return text
    })
    .join('')
}

function indent(text: string, prefix: string): string {
  return text
    .split('\n')
    .map((line, i) => (i === 0 ? line : line ? prefix + line : line))
    .join('\n')
}

function block(node: JSONNode, depth = 0): string {
  const children = node.content ?? []
  switch (node.type) {
    case 'doc':
      return children.map((c) => block(c, depth)).filter((s) => s !== '').join('\n\n')
    case 'paragraph':
      return inline(children)
    case 'heading':
      return `${'#'.repeat(Number(node.attrs?.level ?? 1))} ${inline(children)}`
    case 'blockquote':
      return children.map((c) => block(c, depth)).join('\n\n').split('\n').map((l) => `> ${l}`).join('\n')
    case 'codeBlock': {
      const lang = String(node.attrs?.language ?? '')
      return `\`\`\`${lang}\n${children.map((c) => c.text ?? '').join('')}\n\`\`\``
    }
    case 'horizontalRule':
      return '---'
    case 'image':
      return inline([node])
    case 'bulletList':
      return children.map((item) => `- ${indent(listItem(item, depth), '  ')}`).join('\n')
    case 'orderedList': {
      const start = Number(node.attrs?.start ?? 1)
      return children.map((item, i) => `${start + i}. ${indent(listItem(item, depth), '   ')}`).join('\n')
    }
    case 'taskList':
      return children.map((item) => `- [${item.attrs?.checked ? 'x' : ' '}] ${indent(listItem(item, depth), '  ')}`).join('\n')
    default:
      return children.length ? children.map((c) => block(c, depth)).join('\n\n') : inline([node])
  }
}

function listItem(item: JSONNode, depth: number): string {
  return (item.content ?? []).map((c) => block(c, depth + 1)).join('\n')
}

export function toMarkdown(doc: JSONNode | null | undefined, title?: string): string {
  const body = doc ? block(doc).trim() : ''
  return title ? `# ${title}\n\n${body}\n` : `${body}\n`
}
