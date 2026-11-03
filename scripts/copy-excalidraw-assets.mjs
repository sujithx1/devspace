// Copies Excalidraw's font assets into public/ so the whiteboard works fully offline.
import { cpSync, existsSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const source = join(root, 'node_modules/@excalidraw/excalidraw/dist/prod/fonts')
const target = join(root, 'public/excalidraw-assets/fonts')

if (!existsSync(source)) {
  console.warn('[excalidraw-assets] fonts not found, skipping copy')
} else if (!existsSync(target)) {
  cpSync(source, target, { recursive: true })
  console.log('[excalidraw-assets] copied fonts to public/excalidraw-assets')
}
