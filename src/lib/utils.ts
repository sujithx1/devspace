type ClassValue = string | false | null | undefined | 0

/** Joins truthy class names. */
export function cn(...classes: ClassValue[]): string {
  return classes.filter(Boolean).join(' ')
}

export function debounce<A extends unknown[]>(fn: (...args: A) => void, wait: number) {
  let timer: ReturnType<typeof setTimeout> | undefined
  let lastArgs: A | undefined
  const debounced = (...args: A) => {
    lastArgs = args
    clearTimeout(timer)
    timer = setTimeout(() => {
      timer = undefined
      fn(...args)
    }, wait)
  }
  /** Runs a pending call immediately. */
  debounced.flush = () => {
    if (timer !== undefined && lastArgs) {
      clearTimeout(timer)
      timer = undefined
      fn(...lastArgs)
    }
  }
  debounced.cancel = () => {
    clearTimeout(timer)
    timer = undefined
  }
  return debounced
}

/** Today's date as YYYY-MM-DD in local time. */
export function todayISO(date = new Date()): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

export function parseISODate(value: string): Date {
  const [y, m, d] = value.split('-').map(Number)
  return new Date(y, m - 1, d)
}

export function formatDate(value: string | number, opts: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric' }) {
  const date = typeof value === 'string' ? parseISODate(value) : new Date(value)
  const sameYear = date.getFullYear() === new Date().getFullYear()
  return date.toLocaleDateString(undefined, sameYear ? opts : { ...opts, year: 'numeric' })
}

const rtf = new Intl.RelativeTimeFormat(undefined, { numeric: 'auto' })

export function formatRelative(timestamp: number, now = Date.now()): string {
  const diff = timestamp - now
  const abs = Math.abs(diff)
  const minute = 60_000
  const hour = 60 * minute
  const day = 24 * hour
  if (abs < minute) return 'just now'
  if (abs < hour) return rtf.format(Math.round(diff / minute), 'minute')
  if (abs < day) return rtf.format(Math.round(diff / hour), 'hour')
  if (abs < 7 * day) return rtf.format(Math.round(diff / day), 'day')
  return formatDate(timestamp)
}

/** Whole days from today until `isoDate` (negative when in the past). */
export function daysUntil(isoDate: string, today = todayISO()): number {
  const ms = parseISODate(isoDate).getTime() - parseISODate(today).getTime()
  return Math.round(ms / 86_400_000)
}

export function pluralize(count: number, singular: string, plural = `${singular}s`) {
  return `${count} ${count === 1 ? singular : plural}`
}

export const isMac = typeof navigator !== 'undefined' && /Mac|iPhone|iPad/.test(navigator.platform)
export const modKey = isMac ? '⌘' : 'Ctrl'

/** Returns a snippet of `text` around the first match of `query`. */
export function excerpt(text: string, query: string, radius = 60): string {
  const clean = text.replace(/\s+/g, ' ').trim()
  if (!query) return clean.slice(0, radius * 2)
  const index = clean.toLowerCase().indexOf(query.toLowerCase())
  if (index < 0) return clean.slice(0, radius * 2)
  const start = Math.max(0, index - radius)
  const end = Math.min(clean.length, index + query.length + radius)
  return `${start > 0 ? '…' : ''}${clean.slice(start, end)}${end < clean.length ? '…' : ''}`
}

export function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}

export function slugify(value: string, fallback = 'untitled') {
  const slug = value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
  return slug || fallback
}
