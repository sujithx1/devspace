import { describe, expect, it } from 'vitest'
import { toMarkdown } from './markdown'

describe('toMarkdown', () => {
  it('serializes headings, marks, lists, checklists and code blocks', () => {
    const doc = {
      type: 'doc',
      content: [
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Setup' }] },
        {
          type: 'paragraph',
          content: [
            { type: 'text', text: 'Run ' },
            { type: 'text', text: 'npm i', marks: [{ type: 'code' }] },
            { type: 'text', text: ' then read ' },
            { type: 'text', text: 'docs', marks: [{ type: 'bold' }, { type: 'link', attrs: { href: 'https://x.dev' } }] },
          ],
        },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'one' }] }] }] },
        {
          type: 'taskList',
          content: [
            { type: 'taskItem', attrs: { checked: true }, content: [{ type: 'paragraph', content: [{ type: 'text', text: 'done' }] }] },
            { type: 'taskItem', attrs: { checked: false }, content: [{ type: 'paragraph', content: [{ type: 'text', text: 'todo' }] }] },
          ],
        },
        { type: 'codeBlock', attrs: { language: 'ts' }, content: [{ type: 'text', text: 'const a = 1' }] },
      ],
    }
    expect(toMarkdown(doc, 'Guide')).toBe(
      ['# Guide', '', '## Setup', '', 'Run `npm i` then read [**docs**](https://x.dev)', '', '- one', '', '- [x] done\n- [ ] todo', '', '```ts\nconst a = 1\n```', ''].join('\n'),
    )
  })

  it('handles empty documents', () => {
    expect(toMarkdown(null)).toBe('\n')
  })
})
