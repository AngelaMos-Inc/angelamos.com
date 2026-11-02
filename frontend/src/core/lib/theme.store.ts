// ©AngelaMos | 2026
// theme.store.ts

import { create } from 'zustand'

export type Theme = 'dark' | 'light'

const STORAGE_KEY = 'angelamos-theme'

function readTheme(): Theme {
  try {
    return localStorage.getItem(STORAGE_KEY) === 'light' ? 'light' : 'dark'
  } catch {
    return 'dark'
  }
}

interface ThemeState {
  theme: Theme
  toggle: () => void
}

export const useThemeStore = create<ThemeState>((set, get) => ({
  theme: readTheme(),
  toggle: () => {
    const theme = get().theme === 'dark' ? 'light' : 'dark'
    set({ theme })
    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch {
      return
    }
  },
}))
