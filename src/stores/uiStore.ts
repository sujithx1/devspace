import { create } from 'zustand'

export type ThemePreference = 'light' | 'dark' | 'system'

const THEME_KEY = 'devspace:theme'
const SIDEBAR_KEY = 'devspace:sidebarCollapsed'

function read(key: string): string | null {
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}
function write(key: string, value: string) {
  try {
    localStorage.setItem(key, value)
  } catch {
    // UI preferences are best-effort.
  }
}

const systemDark = () => typeof matchMedia !== 'undefined' && matchMedia('(prefers-color-scheme: dark)').matches

export function resolveTheme(pref: ThemePreference): 'light' | 'dark' {
  return pref === 'system' ? (systemDark() ? 'dark' : 'light') : pref
}

function applyTheme(pref: ThemePreference) {
  const resolved = resolveTheme(pref)
  document.documentElement.classList.toggle('dark', resolved === 'dark')
  return resolved
}

interface UIState {
  theme: ThemePreference
  resolvedTheme: 'light' | 'dark'
  sidebarCollapsed: boolean
  mobileSidebarOpen: boolean
  commandPaletteOpen: boolean
  shortcutsOpen: boolean
  setTheme(theme: ThemePreference): void
  cycleTheme(): void
  syncSystemTheme(): void
  toggleSidebar(): void
  setMobileSidebarOpen(open: boolean): void
  setCommandPaletteOpen(open: boolean): void
  setShortcutsOpen(open: boolean): void
}

const initialTheme = (read(THEME_KEY) as ThemePreference | null) ?? 'system'

export const useUIStore = create<UIState>()((set, get) => ({
  theme: initialTheme,
  resolvedTheme: typeof document !== 'undefined' ? applyTheme(initialTheme) : 'light',
  sidebarCollapsed: read(SIDEBAR_KEY) === 'true',
  mobileSidebarOpen: false,
  commandPaletteOpen: false,
  shortcutsOpen: false,

  setTheme(theme) {
    write(THEME_KEY, theme)
    set({ theme, resolvedTheme: applyTheme(theme) })
  },
  cycleTheme() {
    const order: ThemePreference[] = ['light', 'dark', 'system']
    get().setTheme(order[(order.indexOf(get().theme) + 1) % order.length])
  },
  syncSystemTheme() {
    if (get().theme === 'system') set({ resolvedTheme: applyTheme('system') })
  },
  toggleSidebar() {
    const sidebarCollapsed = !get().sidebarCollapsed
    write(SIDEBAR_KEY, String(sidebarCollapsed))
    set({ sidebarCollapsed })
  },
  setMobileSidebarOpen(mobileSidebarOpen) {
    set({ mobileSidebarOpen })
  },
  setCommandPaletteOpen(commandPaletteOpen) {
    set({ commandPaletteOpen })
  },
  setShortcutsOpen(shortcutsOpen) {
    set({ shortcutsOpen })
  },
}))
