// ===================
// © AngelaMos | 2026
// index.tsx
// ===================

import type { ReactElement } from 'react'
import { Link } from 'react-router-dom'
import { useRepoStats } from '@/api'
import { ROUTES } from '@/config'
import { INSTRUMENTS } from '@/data/instruments'
import styles from './company.module.scss'

interface Arm {
  no: string
  label: string
  name: string
  host: string
  href: string
  external: boolean
  desc: string
  meta: string
  action: string
}

const ARMS: Arm[] = [
  {
    no: '01',
    label: 'education',
    name: 'CertGames',
    host: 'certgames.com',
    href: 'https://certgames.com',
    external: true,
    desc: 'Gamified cybersecurity certification training. Practice questions, hands-on labs, personalized roadmaps, and a resume builder, built so people do not quit before the offer lands.',
    meta: '25,000+ QUESTIONS',
    action: 'OPEN',
  },
  {
    no: '02',
    label: 'research',
    name: 'Lisdex',
    host: 'lisdex.sh',
    href: 'https://lisdex.sh',
    external: true,
    desc: 'Independent malware analysis and investigations, published in full. Delivery chains reconstructed, operator infrastructure assessed, detection rules shipped alongside the findings, plus the OSINT tooling the work runs on.',
    meta: 'PAPERS · DISCLOSURE',
    action: 'OPEN',
  },
  {
    no: '03',
    label: 'tooling',
    name: 'Internals',
    host: 'angelamos.com/index',
    href: ROUTES.INDEX,
    external: false,
    desc: 'Security tools built for my own work and left installable. Every one sets itself up with a single command regardless of dependencies, operating system, or complexity.',
    meta: '',
    action: 'INDEX',
  },
  {
    no: '04',
    label: 'projects',
    name: 'Cybersecurity-Projects',
    host: 'github.com/CarterPerez-dev',
    href: 'https://github.com/CarterPerez-dev/Cybersecurity-Projects',
    external: true,
    desc: 'The open cybersecurity roadmap and project repo. Everything worked through on the way in, kept public so the next person does not have to reassemble it themselves.',
    meta: 'OPEN SOURCE',
    action: 'GITHUB',
  },
]

const content = {
  brand: {
    mono: 'AM',
    mark: 'ANGELAMOS',
  },
  nav: [
    { label: 'COMPANY', to: ROUTES.COMPANY, current: true },
    { label: 'INDEX', to: ROUTES.INDEX, current: false },
    { label: 'CONTACT', to: ROUTES.CONTACT, current: false },
  ],
  plate: '01',
  titleSlab: 'OWNED &',
  titleScript: 'operated',
  figure: {
    src: '/assets/angel.webp',
    alt: 'Winged marble statue with one hand open, lit against black',
  },
  tallyLead: 'ARMS',
  tallySub: 'education · research · tooling · projects',
  footerLeft: 'CarterPerez.dev / 2026',
  footerHref: 'https://lisdex.sh',
  stamp: 'FOUR ARMS · ONE OPERATOR',
}

function metaFor(arm: Arm, tools: number, stars: number | null): string {
  if (arm.no === '03') return `${tools} TOOLS`
  if (arm.no === '04' && stars !== null) {
    return `${stars.toLocaleString()} STARS`
  }
  return arm.meta
}

function Target({ arm }: { arm: Arm }): ReactElement {
  const label = `Open ${arm.name} at ${arm.host}`

  if (!arm.external) {
    return (
      <Link to={arm.href} className={styles.target} aria-label={label}>
        <span className={styles.targetHost}>{arm.host}</span>
        <span className={styles.targetAction}>{arm.action}</span>
      </Link>
    )
  }

  return (
    <a
      className={styles.target}
      href={arm.href}
      target="_blank"
      rel="noreferrer noopener"
      aria-label={`${label} (opens in a new tab)`}
    >
      <span className={styles.targetHost}>{arm.host}</span>
      <span className={styles.targetAction}>{arm.action}</span>
    </a>
  )
}

export function Component(): ReactElement {
  const repo = useRepoStats()
  const stars =
    repo.data?.available && repo.data.stars > 0 ? repo.data.stars : null
  const tools = INSTRUMENTS.length

  return (
    <div className={styles.page}>
      <svg className={styles.svgDefs} aria-hidden="true">
        <defs>
          <filter id="company-grain">
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
        <span className={styles.bracketBR} aria-hidden="true" />

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
          <div className={styles.figureWrap} aria-hidden="true">
            <img
              src={content.figure.src}
              alt=""
              className={styles.figure}
              draggable={false}
            />
            <span className={styles.figureFade} />
            <span className={styles.plumb} />
            <span className={styles.plumbTick} />
          </div>

          <div className={styles.headText}>
            <span className={styles.eyebrow}>
              NO.&nbsp;{content.plate}&nbsp;—&nbsp;COMPANY
            </span>
            <h1 className={styles.title}>
              <span className={styles.titleSlab}>{content.titleSlab}</span>
              <span className={styles.titleScript}>{content.titleScript}</span>
            </h1>
          </div>
        </header>

        <div className={styles.tally}>
          <span className={styles.tallyNum}>
            {String(ARMS.length).padStart(2, '0')}
          </span>
          <div className={styles.tallyText}>
            <span className={styles.tallyLead}>{content.tallyLead}</span>
            <span className={styles.tallySub}>{content.tallySub}</span>
          </div>
        </div>

        <ol className={styles.ledger}>
          {ARMS.map((arm) => (
            <li key={arm.no} className={styles.row}>
              <span className={styles.no}>{arm.no}</span>
              <h2 className={styles.label}>{arm.label}</h2>
              <p className={styles.desc}>{arm.desc}</p>
              <span className={styles.meta}>
                {metaFor(arm, tools, stars)}
              </span>
              <Target arm={arm} />
            </li>
          ))}
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

Component.displayName = 'Company'
