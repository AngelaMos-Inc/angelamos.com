// ©AngelaMos | 2026
// index.tsx

import { Link, useLocation } from 'react-router-dom'
import { ThemeToggle } from '@/components/theme-toggle'
import { ROUTES } from '@/config'
import { useThemeStore } from '@/core/lib/theme.store'
import styles from './not-found.module.scss'

export function Component(): React.ReactElement {
  const theme = useThemeStore((state) => state.theme)
  const plate = theme === 'light' ? '-lux' : ''
  const { pathname } = useLocation()

  return (
    <main className={styles.page}>
      <div className={styles.shell}>
        <header className={styles.runningHead}>
          <Link className={styles.colophon} to={ROUTES.HOME}>
            <span className={styles.mark}>AM</span>
            <span className={styles.rule} aria-hidden="true">
              /
            </span>
            <span>angelamos.com</span>
          </Link>
          <div className={styles.headEnd}>
            <nav className={styles.headNav} aria-label="Main navigation">
              <Link to={ROUTES.INDEX}>index</Link>
              <Link to={ROUTES.COMPANY}>company</Link>
            </nav>
            <ThemeToggle />
          </div>
        </header>

        <section className={styles.body}>
          <span className={styles.section}>error / 404</span>
          <figure className={styles.figure}>
            <img
              className={styles.figureImage}
              src={`/assets/404/plate-404-1000${plate}.webp`}
              srcSet={`/assets/404/plate-404-500${plate}.webp 500w, /assets/404/plate-404-1000${plate}.webp 1000w`}
              sizes="(min-width: 768px) 34rem, calc(100vw - 2.5rem)"
              alt=""
              width={1000}
              height={667}
            />
            <figcaption className={styles.figureCaption}>plate 404</figcaption>
          </figure>

          <h1 className={styles.title}>she was never real</h1>
          <p className={styles.line}>the webpage was never real [404]</p>
          <p className={styles.echo}>
            <span className={styles.echoPath}>{pathname}</span>
            <span className={styles.echoRule} aria-hidden="true" />
            <span className={styles.echoBody}>
              It was never real. The endpoint was a psyop.
            </span>
          </p>
          <Link className={styles.back} to={ROUTES.INDEX}>
            back to the index
          </Link>
        </section>
      </div>
    </main>
  )
}

Component.displayName = 'NotFound'
