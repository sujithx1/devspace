import { Excalidraw, MainMenu, exportToBlob, exportToSvg, getSceneVersion } from '@excalidraw/excalidraw'
import '@excalidraw/excalidraw/index.css'
import type { ExcalidrawElement } from '@excalidraw/excalidraw/element/types'
import type { AppState, BinaryFiles, ExcalidrawImperativeAPI, ExcalidrawInitialDataState } from '@excalidraw/excalidraw/types'
import { forwardRef, useImperativeHandle, useLayoutEffect, useRef, useState } from 'react'
import type { DrawingScene } from '@/data'

/** Persisted appState keys: view and tool preferences only, never transient UI state. */
const PERSISTED_APP_STATE = [
  'viewBackgroundColor',
  'gridModeEnabled',
  'gridSize',
  'gridStep',
  'zoom',
  'scrollX',
  'scrollY',
  'currentItemStrokeColor',
  'currentItemBackgroundColor',
  'currentItemStrokeWidth',
  'currentItemStrokeStyle',
  'currentItemFillStyle',
  'currentItemRoughness',
  'currentItemOpacity',
  'currentItemFontFamily',
  'currentItemFontSize',
] as const satisfies readonly (keyof AppState)[]

export interface SceneChange {
  scene: DrawingScene
  /** True when elements changed (as opposed to only scroll/zoom/style). */
  contentChanged: boolean
}

export interface WhiteboardHandle {
  exportPng(): Promise<Blob>
  exportSvg(): Promise<Blob>
  thumbnail(): Promise<string | null>
}

interface Props {
  initialScene: DrawingScene
  theme: 'light' | 'dark'
  onChange: (change: SceneChange) => void
  /** View mode: pan and zoom only. */
  readOnly?: boolean
}

function liveElements(elements: readonly ExcalidrawElement[]) {
  return elements.filter((el) => !el.isDeleted)
}

/** Keeps only binary files that are still referenced by an element. */
function referencedFiles(elements: readonly ExcalidrawElement[], files: BinaryFiles): BinaryFiles {
  const ids = new Set<string>(elements.flatMap((el) => ('fileId' in el && el.fileId ? [el.fileId as string] : [])))
  return Object.fromEntries(Object.entries(files).filter(([id]) => ids.has(id))) as BinaryFiles
}

function blobToDataUrl(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(String(reader.result))
    reader.onerror = () => reject(reader.error)
    reader.readAsDataURL(blob)
  })
}

/**
 * Wraps the Excalidraw engine. Excalidraw provides the drawing tools (pen,
 * eraser, selection, shapes, arrows, text, colours, stroke width, undo/redo,
 * zoom/pan, grid); this component handles persistence and export.
 */
const WhiteboardCanvas = forwardRef<WhiteboardHandle, Props>(function WhiteboardCanvas({ initialScene, theme, readOnly = false, onChange }, ref) {
  const apiRef = useRef<ExcalidrawImperativeAPI | null>(null)
  const lastVersion = useRef<number | null>(null)
  const lastViewKey = useRef('')
  const onChangeRef = useRef(onChange)
  useLayoutEffect(() => {
    onChangeRef.current = onChange
  })

  // Seeds the editor once; later scene changes flow out through onChange only.
  const [initialData] = useState<ExcalidrawInitialDataState>(() => ({
    elements: initialScene.elements as ExcalidrawElement[],
    appState: { gridModeEnabled: true, ...(initialScene.appState as Partial<AppState>) },
    files: initialScene.files as BinaryFiles,
    scrollToContent: !('scrollX' in initialScene.appState),
  }))

  const exportBase = () => {
    const api = apiRef.current
    if (!api) throw new Error('Whiteboard is not ready')
    const elements = liveElements(api.getSceneElements())
    if (elements.length === 0) throw new Error('Nothing to export — the canvas is empty')
    return { elements, appState: { ...api.getAppState(), exportBackground: true }, files: api.getFiles() }
  }

  useImperativeHandle(ref, () => ({
    async exportPng() {
      return exportToBlob({ ...exportBase(), mimeType: 'image/png', exportPadding: 24, getDimensions: (w: number, h: number) => ({ width: w * 2, height: h * 2, scale: 2 }) })
    },
    async exportSvg() {
      const svg = await exportToSvg({ ...exportBase(), exportPadding: 24 })
      return new Blob([svg.outerHTML], { type: 'image/svg+xml' })
    },
    async thumbnail() {
      const api = apiRef.current
      if (!api) return null
      const elements = liveElements(api.getSceneElements())
      if (elements.length === 0) return null
      const blob = await exportToBlob({
        elements,
        // Transparent, light-mode render; cards invert it in dark mode.
        appState: { ...api.getAppState(), exportBackground: false, exportWithDarkMode: false },
        files: api.getFiles(),
        mimeType: 'image/png',
        maxWidthOrHeight: 480,
        exportPadding: 16,
      })
      return blobToDataUrl(blob)
    },
  }))

  const handleChange = (elements: readonly ExcalidrawElement[], appState: AppState, files: BinaryFiles) => {
    const version = getSceneVersion(elements)
    const viewKey = PERSISTED_APP_STATE.map((k) => JSON.stringify(appState[k])).join('|')
    const contentChanged = lastVersion.current !== null && version !== lastVersion.current
    const viewChanged = lastViewKey.current !== '' && viewKey !== lastViewKey.current
    const firstCall = lastVersion.current === null
    lastVersion.current = version
    lastViewKey.current = viewKey
    if (firstCall || (!contentChanged && !viewChanged)) return

    const persisted = Object.fromEntries(PERSISTED_APP_STATE.map((k) => [k, appState[k]]))
    const live = liveElements(elements)
    onChangeRef.current({
      scene: { elements: live as unknown[], appState: persisted, files: referencedFiles(live, files) as Record<string, unknown> },
      contentChanged,
    })
  }

  return (
    <div className="excalidraw-host h-full w-full">
      <Excalidraw
        excalidrawAPI={(api) => {
          apiRef.current = api
        }}
        initialData={initialData}
        theme={theme}
        viewModeEnabled={readOnly}
        onChange={handleChange}
        UIOptions={{ canvasActions: { loadScene: false, saveToActiveFile: false, toggleTheme: null } }}
      >
        <MainMenu>
          <MainMenu.DefaultItems.SaveAsImage />
          <MainMenu.DefaultItems.Export />
          <MainMenu.DefaultItems.ClearCanvas />
          <MainMenu.Separator />
          <MainMenu.DefaultItems.ChangeCanvasBackground />
          <MainMenu.DefaultItems.Help />
        </MainMenu>
      </Excalidraw>
    </div>
  )
})

export default WhiteboardCanvas
