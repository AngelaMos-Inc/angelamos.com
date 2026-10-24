// ===================
// © AngelaMos | 2026
// index.tsx
// ===================

import {
  type ReactElement,
  useCallback,
  useEffect,
  useRef,
  useState,
} from 'react'
import { Link } from 'react-router-dom'
import { ROUTES } from '@/config'
import { INSTRUMENTS, type Instrument } from '@/data/instruments'
import styles from './registry.module.scss'

const content = {
  brand: {
    mono: 'AM',
    mark: 'ANGELAMOS',
  },
  nav: [
    { label: 'COMPANY', to: ROUTES.COMPANY, current: false },
    { label: 'INDEX', to: ROUTES.INDEX, current: true },
    { label: 'CONTACT', to: ROUTES.CONTACT, current: false },
  ],
  plate: '02',
  title: 'internals',
  intro:
    'All my internal tooling, built by me, for me. Part of my development philosophy: every tool installs and sets itself up with one command, no matter the dependencies, operating system, or complexity. I implore you to do the same.',
  figure: {
    src: '/assets/interior.webp',
    alt: 'Close crop of a downcast anime eye in cold blue light',
    label: 'INTERIOR · VIEW',
  },
  footerLeft: 'CarterPerez.dev / 2026',
  footerHref: 'https://lisdex.sh',
  stamp: 'CURL · PIPE · BASH',
}

function command(path: string): string {
  const base = path ? `https://angelamos.com/${path}` : 'https://angelamos.com'
  return `curl -fsSL ${base}/install.sh | bash`
}

function fallbackCopy(text: string): void {
  const ta = document.createElement('textarea')
  ta.value = text
  ta.style.position = 'fixed'
  ta.style.opacity = '0'
  document.body.appendChild(ta)
  ta.select()
  try {
    document.execCommand('copy')
  } finally {
    document.body.removeChild(ta)
  }
}

export function Component(): ReactElement {
  const [copied, setCopied] = useState<string | null>(null)
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    return () => {
      if (timer.current) clearTimeout(timer.current)
    }
  }, [])

  const copy = useCallback((tool: Instrument) => {
    const text = command(tool.path)
    const write = navigator.clipboard?.writeText
      ? navigator.clipboard.writeText(text)
      : Promise.reject(new Error('no clipboard'))

    write
      .catch(() => fallbackCopy(text))
      .finally(() => {
        setCopied(tool.no)
        if (timer.current) clearTimeout(timer.current)
        timer.current = setTimeout(() => setCopied(null), 2400)
      })
  }, [])

  return (
    <div className={styles.page}>
      <svg className={styles.svgDefs} aria-hidden="true">
        <defs>
          <filter id="index-grade" colorInterpolationFilters="sRGB">
            <feColorMatrix type="saturate" values="0.22" />
            <feComponentTransfer>
              <feFuncR type="table" tableValues="0.02 0.05 0.14 0.5 0.86 0.96" />
              <feFuncG type="table" tableValues="0.02 0.05 0.15 0.52 0.88 0.97" />
              <feFuncB type="table" tableValues="0.03 0.07 0.18 0.57 0.92 1" />
            </feComponentTransfer>
          </filter>
          <filter id="index-grain">
            <feTurbulence
              type="fractalNoise"
              baseFrequency="0.9"
              numOctaves="2"
              stitchTiles="stitch"
            />
            <feColorMatrix
              type="matrix"
              values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.5 0"
            />
          </filter>
        </defs>
      </svg>

      <div className={styles.halftone} aria-hidden="true" />
      <div className={styles.grain} aria-hidden="true" />
      <div className={styles.vignette} aria-hidden="true" />

      <div className={styles.stage}>
        <span className={styles.bracketTL} aria-hidden="true" />

        <nav className={styles.nav}>
          <Link
            to={ROUTES.HOME}
            className={styles.brandGroup}
            aria-label="Angelamos — home"
          >
            <span className={styles.brandMono}>{content.brand.mono}</span>
            <span className={styles.brandMark}>
              <span className={styles.brandCopy}>©</span>
              {content.brand.mark}
            </span>
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
          <div className={styles.headText}>
            <span className={styles.eyebrow}>
              NO.&nbsp;{content.plate}&nbsp;—&nbsp;INDEX
            </span>
            <h1 className={styles.title}>
              <span className={styles.titleInner}>{content.title}</span>
            </h1>
            <p className={styles.intro}>{content.intro}</p>
          </div>

          <figure className={styles.plate}>
            <div className={styles.plateFrame}>
              <img
                src={content.figure.src}
                alt={content.figure.alt}
                className={styles.plateImg}
                draggable={false}
              />
              <span className={styles.reticle} aria-hidden="true" />
              <span className={styles.tick} aria-hidden="true" />
            </div>
            <figcaption className={styles.plateMeta}>
              <span className={styles.plateLabel}>{content.figure.label}</span>
              <span className={styles.count}>
                {String(INSTRUMENTS.length).padStart(2, '0')}&nbsp;&nbsp;FILED
              </span>
            </figcaption>
          </figure>
        </header>

        <ol className={styles.ledger}>
          {INSTRUMENTS.map((tool) => {
            const isCopied = copied === tool.no
            return (
              <li key={tool.no} className={styles.row}>
                <span className={styles.no}>{tool.no}</span>
                <h2 className={styles.name}>{tool.name}</h2>
                <p className={styles.desc}>{tool.desc}</p>
                <span className={styles.lang}>{tool.lang}</span>
                <button
                  type="button"
                  className={`${styles.cmd} ${isCopied ? styles.cmdCopied : ''}`}
                  onClick={() => copy(tool)}
                  aria-label={`Copy install command for ${tool.name}`}
                  title={command(tool.path)}
                >
                  <span className={styles.cmdPrompt}>$</span>
                  <code className={styles.cmdText}>{command(tool.path)}</code>
                  <span className={styles.cmdAction}>
                    {isCopied ? 'COPIED' : 'COPY'}
                  </span>
                </button>
              </li>
            )
          })}
        </ol>

        <footer className={styles.footer}>
          <a
            className={styles.footerLeft}
            href={content.footerHref}
            target="_blank"
            rel="noreferrer noopener"
          >
            {content.footerLeft}
          </a>
          <span className={styles.footerCenter}>{content.stamp}</span>
          <span className={styles.footerRight}>
            <span className={styles.footerDash}>&mdash;</span>
            <span className={styles.footerNumber}>{content.plate}</span>
            <span className={styles.footerDash}>&mdash;</span>
          </span>
        </footer>
      </div>
    </div>
  )
}

Component.displayName = 'Index'
