import { AnimatePresence, motion } from 'framer-motion'
import { CheckCircle2, Info, X, XCircle } from 'lucide-react'
import { createPortal } from 'react-dom'
import { useToastStore } from '@/stores/toastStore'

const icons = {
  success: <CheckCircle2 className="size-4 text-success" />,
  error: <XCircle className="size-4 text-danger" />,
  info: <Info className="size-4 text-accent" />,
}

export function Toaster() {
  const { toasts, dismiss } = useToastStore()
  return createPortal(
    <div
      className="pointer-events-none fixed right-4 bottom-4 z-[70] flex w-[min(360px,calc(100vw-2rem))] flex-col gap-2"
      aria-live="polite"
      role="status"
    >
      <AnimatePresence initial={false}>
        {toasts.map((t) => (
          <motion.div
            key={t.id}
            layout
            initial={{ opacity: 0, y: 12, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, x: 24, transition: { duration: 0.15 } }}
            className="pointer-events-auto flex items-start gap-3 rounded-lg border border-line bg-elevated px-3.5 py-3 text-sm shadow-lg shadow-black/10"
          >
            <span className="mt-0.5">{icons[t.kind]}</span>
            <p className="flex-1 leading-snug">{t.message}</p>
            {t.action && (
              <button
                type="button"
                className="text-xs font-semibold text-accent hover:underline"
                onClick={() => {
                  t.action?.onClick()
                  dismiss(t.id)
                }}
              >
                {t.action.label}
              </button>
            )}
            <button type="button" aria-label="Dismiss notification" onClick={() => dismiss(t.id)} className="text-fg-subtle hover:text-fg">
              <X className="size-3.5" />
            </button>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>,
    document.body,
  )
}
