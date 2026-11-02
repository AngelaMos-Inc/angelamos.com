// ©AngelaMos | 2026
// theme-toggle.tsx

import { RiContrastFill } from 'react-icons/ri'
import { useThemeStore } from '@/core/lib/theme.store'
import styles from './theme-toggle.module.scss'

export function ThemeToggle(): React.ReactElement {
  const { theme, toggle } = useThemeStore()
  const label = `Switch to ${theme === 'dark' ? 'light' : 'dark'} mode`

  return (
    <button
      type="button"
      className={styles.toggle}
      aria-label={label}
      title={label}
      onClick={toggle}
    >
      <RiContrastFill
        className={theme === 'light' ? styles.light : undefined}
        aria-hidden="true"
      />
    </button>
  )
}
