// ===================
// © AngelaMos | 2026
// index.tsx
// ===================

import type { ReactElement } from 'react'
import { Link } from 'react-router-dom'
import { ROUTES } from '@/config'
import styles from './registry.module.scss'

const content = {
  brand: {
    mono: 'AM',
    mark: '©ANGELAMOS',
  },
  nav: [
    { label: 'INDEX', to: ROUTES.INDEX, current: true },
    { label: 'ARCHIVE', to: ROUTES.ARCHIVE, current: false },
    { label: 'CONTACT', to: ROUTES.CONTACT, current: false },
  ],
  plate: '04',
  title: 'extant',
  eyebrow: 'NO. 04 — THE REGISTER',
  intro:
    'A REGISTER OF WHAT STILL EXISTS. EACH ENTRY A PLATE — EACH PLATE A ROOM YOU HAVE NOT BEEN GIVEN YET.',
  columns: ['Nº', 'TITLE', 'FIELD', 'YEAR', 'STATE'],
  footerLeft: 'CarterPerez-dev / 2026',
  stamp: '38°53′N 77°02′W',
  date: '2026·05·30',
}

const works = [
  { n: '01', title: 'certgames', field: 'SYSTEMIZATION', year: '2025', state: 'EXTANT' },
  { n: '02', title: 'iminthewalls', field: 'SURVEILLANCE', year: '2026', state: 'EXTANT' },
  { n: '03', title: 'iglowinthedark', field: 'STRATAGEM', year: '2026', state: 'EXTANT' },
  { n: '04', title: 'axumortem', field: 'SYNTHESIS', year: '2026', state: 'EXTANT' },
  { n: '05', title: '—', field: 'SANITIZED', year: '——', state: 'NASCENT' },
] as const

function stateClass(state: string): string {
  if (state === 'DORMANT') return styles.stateDormant
  if (state === 'NASCENT') return styles.stateInterred
  return styles.stateExtant
}

export function Component(): ReactElement {
  return (
    <div className={styles.page}>
      <svg className={styles.svgDefs} aria-hidden="true">
        <defs>
          <filter id="registry-grain">
            <feTurbulence
              type="fractalNoise"
              baseFrequency="0.9"
              numOctaves="2"
              stitchTiles="stitch"
            />
            <feColorMatrix
              type="matrix"
              values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.46 0"
            />
          </filter>
        </defs>
      </svg>

      <main className={styles.poster}>
        <div className={styles.stage}>
          <span className={styles.bracketTL} aria-hidden="true" />
          <span className={styles.bracketBR} aria-hidden="true" />

          <nav className={styles.nav}>
            <Link
              to={ROUTES.HOME}
              className={styles.brandGroup}
              aria-label="AngelaMos — home"
            >
              <span className={styles.brandMono}>{content.brand.mono}</span>
              <span className={styles.brandMark}>{content.brand.mark}</span>
            </Link>
            <ul className={styles.navItems}>
              {content.nav.map((item) => (
                <li key={item.label}>
                  <Link
                    to={item.to}
                    className={`${styles.navLink} ${
                      item.current ? styles.navCurrent : ''
                    }`}
                    aria-current={item.current ? 'page' : undefined}
                  >
                    {item.label}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>

          <header className={styles.head}>
            <span className={styles.eyebrow}>{content.eyebrow}</span>
            <h1 className={styles.title}>
              <span className={styles.titleInner}>{content.title}</span>
            </h1>
            <p className={styles.intro}>{content.intro}</p>
          </header>

          <section className={styles.register} aria-label="Register of works">
            <div className={`${styles.row} ${styles.rowHead}`}>
              <span className={styles.cellNum}>{content.columns[0]}</span>
              <span className={styles.cellTitle}>{content.columns[1]}</span>
              <span className={styles.cellField}>{content.columns[2]}</span>
              <span className={styles.cellYear}>{content.columns[3]}</span>
              <span className={styles.cellState}>{content.columns[4]}</span>
            </div>

            <ol className={styles.rows}>
              {works.map((w) => (
                <li key={w.n} className={styles.row}>
                  <span className={styles.cellNum}>
                    <span className={styles.cross} aria-hidden="true" />
                    {w.n}
                  </span>
                  <span className={styles.cellTitle}>{w.title}</span>
                  <span className={styles.cellField}>{w.field}</span>
                  <span className={styles.cellYear}>{w.year}</span>
                  <span className={`${styles.cellState} ${stateClass(w.state)}`}>
                    {w.state}
                  </span>
                </li>
              ))}
            </ol>
          </section>

          <footer className={styles.footer}>
            <span className={styles.footerLeft}>{content.footerLeft}</span>
            <span className={styles.footerCenter}>
              {content.stamp}&nbsp;&nbsp;·&nbsp;&nbsp;{content.date}
            </span>
            <span className={styles.footerRight}>
              <span className={styles.footerDash}>&mdash;</span>
              <span className={styles.footerNumber}>{content.plate}</span>
              <span className={styles.footerDash}>&mdash;</span>
            </span>
          </footer>
        </div>

        <div className={styles.halftone} aria-hidden="true" />
        <div className={styles.grain} aria-hidden="true" />
        <div className={styles.vignette} aria-hidden="true" />
      </main>
    </div>
  )
}

Component.displayName = 'Index'
