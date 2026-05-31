// ===================
// © AngelaMos | 2026
// index.tsx
// ===================

import { type ReactElement, useState } from 'react'
import { Link } from 'react-router-dom'
import { ROUTES } from '@/config'
import styles from './archive.module.scss'

const content = {
  brand: {
    mono: 'AM',
    mark: '©ANGELAMOS',
  },
  nav: [
    { label: 'INDEX', to: ROUTES.INDEX, current: false },
    { label: 'ARCHIVE', to: ROUTES.ARCHIVE, current: true },
    { label: 'CONTACT', to: ROUTES.CONTACT, current: false },
  ],
  plate: '05',
  title: 'strata',
  eyebrow: 'NO. 05 — THE VAULT',
  intro:
    'EVERYTHING THE STUDIO HAS LET GO OF, FILED BY THE DAY IT LEFT. SOME OF IT YOU CAN STILL DIG UP AND RUN.',
  footerLeft: 'CarterPerez-dev / 2026',
  stamp: '38°53′N 77°02′W',
  date: '2026·05·30',
}

type Entry = {
  id: string
  date: string
  title: string
  tag: string
  note?: string
  cmd?: string
  hash?: string
}

const entries: Entry[] = [
  {
    id: 'audience',
    date: '2026·05·30',
    title: 'audience',
    tag: 'PLATE',
    note: 'The third room opened. A door dressed as a letter.',
  },
  {
    id: 'angela',
    date: '2026·02·09',
    title: 'angela',
    tag: 'SCRIPT',
    note: 'The first room was created in confidence.',
    cmd: 'curl -fsSL https://angelamos.com/install.sh | bash',
    hash: 'sha256:9f2c1ad7e4b80c6f5e1a3d92b7c044fe8a61d0c3927bb45e6f8a2c1d0e7b3a94',
  },
  {
    id: 'hollowed',
    date: '2026·05·18',
    title: 'hollowed',
    tag: 'PLATE',
    note: 'Pretending to be the second door.',
  },
  {
    id: 'portia',
    date: '2026·03·05',
    title: 'portia',
    tag: 'SCRIPT',
    note: 'Installs the truth. Do not run what you have not read.',
    cmd: 'curl -fsSL https://angelamos.com/portia/install.sh | bash',
    hash: 'sha256:3b7d0e91c2a64f58d1e0a4c7b9f23106e8d5c4a2916f0b7d3e8a1c602f4d9b85',
  },
  {
    id: 'angelmos-3d',
    date: '2026·01·22',
    title: 'angelamos 3d',
    tag: '3D',
    note: 'anthropomorphized.',
    cmd: 'curl -fsSL https://angelamos.com/3d/install.sh | bash',
  },
] as const

export function Component(): ReactElement {
  const [copied, setCopied] = useState<string | null>(null)

  function copy(id: string, text: string): void {
    void navigator.clipboard?.writeText(text)
    setCopied(id)
    window.setTimeout(() => {
      setCopied((c) => (c === id ? null : c))
    }, 1800)
  }

  return (
    <div className={styles.page}>
      <svg className={styles.svgDefs} aria-hidden="true">
        <defs>
          <filter id="strata-grain">
            <feTurbulence
              type="fractalNoise"
              baseFrequency="0.85"
              numOctaves="3"
              stitchTiles="stitch"
            />
            <feColorMatrix
              type="matrix"
              values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.6 0"
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

          <section className={styles.vault} aria-label="The vault">
            {entries.map((e) => (
              <article key={e.id} className={styles.entry}>
                <div className={styles.entryMeta}>
                  <span className={styles.entryDate}>{e.date}</span>
                  <span
                    className={`${styles.entryTag} ${
                      e.cmd ? styles.entryTagScript : ''
                    }`}
                  >
                    {e.tag}
                  </span>
                </div>

                <div className={styles.entryBody}>
                  <h2 className={styles.entryTitle}>{e.title}</h2>
                  {e.note ? (
                    <p className={styles.entryNote}>{e.note}</p>
                  ) : null}

                  {e.cmd ? (
                    <div className={styles.spell}>
                      <button
                        type="button"
                        className={styles.spellCmd}
                        onClick={() => copy(e.id, e.cmd ?? '')}
                        aria-label={`Copy install command for ${e.title}`}
                      >
                        <span className={styles.prompt}>$</span>
                        <code className={styles.code}>{e.cmd}</code>
                        <span className={styles.copy}>
                          {copied === e.id ? 'TAKEN' : 'COPY'}
                        </span>
                      </button>
                      {e.hash ? (
                        <span className={styles.hash}>{e.hash}</span>
                      ) : null}
                    </div>
                  ) : null}
                </div>
              </article>
            ))}
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

Component.displayName = 'Archive'
