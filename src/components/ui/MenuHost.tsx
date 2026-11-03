import { AnimatePresence, motion } from 'framer-motion'
import { Check } from 'lucide-react'
import { useEffect, useLayoutEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { cn } from '@/lib/utils'
import { useMenuStore } from '@/stores/menuStore'

/** Renders the single global context/dropdown menu. Mounted once at the app root. */
export function MenuHost() {
  const { open, x, y, items, hide } = useMenuStore()
  const ref = useRef<HTMLDivElement>(null)
  const [pos, setPos] = useState({ left: x, top: y })

  useLayoutEffect(() => {
    if (!open || !ref.current) return
    const { width, height } = ref.current.getBoundingClientRect()
    setPos({
      left: Math.max(8, Math.min(x, window.innerWidth - width - 8)),
      top: y + height > window.innerHeight - 8 ? Math.max(8, y - height) : y,
    })
  }, [open, x, y, items])

  useEffect(() => {
    if (!open) return
    const previous = document.activeElement as HTMLElement | null
    ref.current?.querySelector<HTMLElement>('[role="menuitem"]:not([aria-disabled="true"])')?.focus()
    const onPointer = (e: PointerEvent) => {
      if (!ref.current?.contains(e.target as Node)) hide()
    }
    const close = () => hide()
    window.addEventListener('pointerdown', onPointer, true)
    window.addEventListener('blur', close)
    window.addEventListener('resize', close)
    window.addEventListener('scroll', close, true)
    return () => {
      window.removeEventListener('pointerdown', onPointer, true)
      window.removeEventListener('blur', close)
      window.removeEventListener('resize', close)
      window.removeEventListener('scroll', close, true)
      previous?.focus?.()
    }
  }, [open, hide])

  const onKeyDown = (e: React.KeyboardEvent) => {
    const nodes = Array.from(ref.current?.querySelectorAll<HTMLElement>('[role="menuitem"]:not([aria-disabled="true"])') ?? [])
    const index = nodes.indexOf(document.activeElement as HTMLElement)
    if (e.key === 'Escape' || e.key === 'Tab') {
      e.preventDefault()
      hide()
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      nodes[(index + 1) % nodes.length]?.focus()
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      nodes[(index - 1 + nodes.length) % nodes.length]?.focus()
    }
  }

  return createPortal(
    <AnimatePresence>
      {open && (
        <motion.div
          ref={ref}
          role="menu"
          onKeyDown={onKeyDown}
          onContextMenu={(e) => e.preventDefault()}
          initial={{ opacity: 0, scale: 0.97 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.97, transition: { duration: 0.08 } }}
          transition={{ duration: 0.1 }}
          style={{ left: pos.left, top: pos.top }}
          className="fixed z-[60] max-h-[70vh] min-w-48 overflow-y-auto rounded-lg border border-line bg-elevated p-1 shadow-xl shadow-black/15"
        >
          {items.map((item, i) => {
            if (item.type === 'separator') return <div key={i} role="separator" className="my-1 h-px bg-line" />
            if (item.type === 'label')
              return (
                <div key={i} className="px-2 pt-1.5 pb-1 text-[11px] font-medium tracking-wide text-fg-subtle uppercase">
                  {item.label}
                </div>
              )
            const Icon = item.icon
            return (
              <button
                key={i}
                type="button"
                role="menuitem"
                aria-disabled={item.disabled || undefined}
                disabled={item.disabled}
                onClick={() => {
                  hide()
                  item.onSelect()
                }}
                className={cn(
                  'flex w-full items-center gap-2.5 rounded-md px-2 py-1.5 text-left text-sm outline-none',
                  'focus:bg-surface-2 hover:bg-surface-2 disabled:opacity-40',
                  item.danger ? 'text-danger' : 'text-fg',
                )}
              >
                {Icon ? <Icon className="size-4 shrink-0 opacity-70" /> : item.checked !== undefined && <span className="size-4" />}
                <span className="flex-1 truncate">{item.label}</span>
                {item.checked && <Check className="size-3.5 text-accent" />}
                {item.shortcut && <span className="text-xs text-fg-subtle">{item.shortcut}</span>}
              </button>
            )
          })}
        </motion.div>
      )}
    </AnimatePresence>,
    document.body,
  )
}
