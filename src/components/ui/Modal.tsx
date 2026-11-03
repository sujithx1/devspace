import { AnimatePresence, motion } from 'framer-motion'
import { X } from 'lucide-react'
import { useEffect, useId, useRef, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { cn } from '@/lib/utils'

interface ModalProps {
  open: boolean
  onClose: () => void
  title: string
  description?: string
  children: ReactNode
  footer?: ReactNode
  size?: 'sm' | 'md' | 'lg'
  /** Hide the visible header (title is still announced to screen readers). */
  bare?: boolean
  className?: string
}

const FOCUSABLE = 'a[href],button:not([disabled]),textarea,input,select,[tabindex]:not([tabindex="-1"])'

export function Modal({ open, onClose, title, description, children, footer, size = 'md', bare, className }: ModalProps) {
  const panelRef = useRef<HTMLDivElement>(null)
  const titleId = useId()
  const restoreFocus = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (!open) return
    restoreFocus.current = document.activeElement as HTMLElement | null
    const frame = requestAnimationFrame(() => {
      const panel = panelRef.current
      if (!panel || panel.contains(document.activeElement)) return
      const auto = panel.querySelector<HTMLElement>('[autofocus],[data-autofocus]')
      ;(auto ?? panel.querySelector<HTMLElement>(FOCUSABLE) ?? panel).focus()
    })
    return () => {
      cancelAnimationFrame(frame)
      restoreFocus.current?.focus?.()
    }
  }, [open])

  const onKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      e.stopPropagation()
      onClose()
    }
    if (e.key === 'Tab' && panelRef.current) {
      const nodes = Array.from(panelRef.current.querySelectorAll<HTMLElement>(FOCUSABLE))
      if (nodes.length === 0) return
      const first = nodes[0]
      const last = nodes[nodes.length - 1]
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault()
        last.focus()
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault()
        first.focus()
      }
    }
  }

  return createPortal(
    <AnimatePresence>
      {open && (
        <div className="fixed inset-0 z-50 flex items-start justify-center p-4 pt-[12vh]" onKeyDown={onKeyDown}>
          <motion.div
            className="absolute inset-0 bg-black/40 backdrop-blur-[2px]"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.15 }}
            onClick={onClose}
          />
          <motion.div
            ref={panelRef}
            role="dialog"
            aria-modal="true"
            aria-labelledby={titleId}
            tabIndex={-1}
            initial={{ opacity: 0, y: 8, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 4, scale: 0.98 }}
            transition={{ duration: 0.16, ease: 'easeOut' }}
            className={cn(
              'relative w-full overflow-hidden rounded-xl border border-line bg-elevated shadow-2xl shadow-black/20 outline-none',
              size === 'sm' && 'max-w-sm',
              size === 'md' && 'max-w-lg',
              size === 'lg' && 'max-w-2xl',
              className,
            )}
          >
            {bare ? (
              <h2 id={titleId} className="sr-only">
                {title}
              </h2>
            ) : (
              <div className="flex items-start justify-between gap-4 px-5 pt-5">
                <div>
                  <h2 id={titleId} className="text-base font-semibold">
                    {title}
                  </h2>
                  {description && <p className="mt-1 text-sm text-fg-muted">{description}</p>}
                </div>
                <button
                  type="button"
                  onClick={onClose}
                  aria-label="Close dialog"
                  className="-mr-1 rounded-md p-1 text-fg-subtle hover:bg-surface-2 hover:text-fg"
                >
                  <X className="size-4" />
                </button>
              </div>
            )}
            {children != null ? <div className={cn(!bare && 'px-5 py-4')}>{children}</div> : <div className="h-4" />}
            {footer && <div className="flex justify-end gap-2 border-t border-line bg-surface-2/50 px-5 py-3">{footer}</div>}
          </motion.div>
        </div>
      )}
    </AnimatePresence>,
    document.body,
  )
}
