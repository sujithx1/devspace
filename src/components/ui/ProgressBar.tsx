import { cn } from '@/lib/utils'

export function ProgressBar({ value, className, barClassName, label }: { value: number; className?: string; barClassName?: string; label: string }) {
  const clamped = Math.max(0, Math.min(100, value))
  return (
    <div role="progressbar" aria-label={label} aria-valuenow={clamped} aria-valuemin={0} aria-valuemax={100} className={cn('h-1.5 overflow-hidden rounded-full bg-surface-2', className)}>
      <div className={cn('h-full rounded-full bg-accent transition-[width] duration-500', barClassName)} style={{ width: `${clamped}%` }} />
    </div>
  )
}
