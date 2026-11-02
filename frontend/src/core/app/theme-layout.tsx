// ©AngelaMos | 2026
// theme-layout.tsx

import { useLayoutEffect } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { Toaster } from 'sonner'
import { useThemeStore } from '@/core/lib/theme.store'

export function ThemeLayout(): React.ReactElement {
  const { pathname } = useLocation()
  const preferredTheme = useThemeStore((state) => state.theme)
  const isHome = pathname === '/'
  const theme = isHome ? 'dark' : preferredTheme

  useLayoutEffect(() => {
    const root = document.documentElement
    root.dataset.theme = theme
    root.dataset.page = isHome ? 'home' : 'inner'
  }, [theme, isHome])

  return (
    <>
      <Outlet />
      <Toaster
        position="top-right"
        duration={2000}
        theme={theme}
        toastOptions={{
          style: {
            background: 'var(--toast-ground)',
            border: '1px solid var(--page-line)',
            color: 'var(--page-ink)',
          },
        }}
      />
    </>
  )
}
