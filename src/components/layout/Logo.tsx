import { cn } from '@/lib/utils'

export function LogoMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" aria-hidden="true" className={cn('size-7', className)}>
      <rect width="32" height="32" rx="8" className="fill-accent" />
      <path d="M11 10l-5 6 5 6M21 10l5 6-5 6M18 8l-4 16" stroke="#fff" strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

export function Logo({ className }: { className?: string }) {
  return (
    <div className={cn('flex items-center gap-2', className)}>
      <LogoMark />
      <span className="text-[15px] font-semibold tracking-tight">DevSpace</span>
    </div>
  )
}
