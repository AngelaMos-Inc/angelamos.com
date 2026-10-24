// ===================
// © AngelaMos | 2026
// index.tsx
// ===================

import { Link } from 'react-router-dom'
import { ROUTES } from '@/config'
import styles from './landing.module.scss'

const content = {
  brand: {
    mono: 'AM',
    mark: 'ANGELAMOS',
  },
  nav: [
    { label: 'COMPANY', href: null, to: ROUTES.COMPANY },
    { label: 'INDEX', href: null, to: ROUTES.INDEX },
    { label: 'CONTACT', href: null, to: ROUTES.CONTACT },
  ],
  bannerLeft: 'ONE',
  bannerRight: 'NONE',
  bannerBody:
    'ABSENCE IS WHAT FILLS THE SPACE LEFT BY QUITTING. WHATEVER WE WALKED AWAY FROM CONTINUES TO TAKE UP ROOM IN A LIFE WE NEVER.',
  headline: 'hollowed',
  bodyLeft:
    'EVERY HOLLOW HOLDS A NEGATIVE PORTRAIT OF WHAT ONCE LIVED INSIDE IT. THE SHAPE OF MISSING IS ALWAYS SHARPER, ALWAYS HEAVIER, THAN THE SHAPE OF HAVING.',
  bodyRight:
    'WHAT WE LEAVE UNSAID HOLDS MORE WEIGHT THAN WHAT WE CHOOSE.',
  footerLeft: 'CarterPerez.dev / 2026',
  footerHref: 'https://lisdex.sh',
  footerNumber: '00',
  portraitSrc: '/assets/portrait.webp',
  portraitAlt: 'Hollowed cover portrait',
}

export function Component(): React.ReactElement {
  return (
    <div className={styles.page}>
      <svg className={styles.svgDefs} aria-hidden="true">
        <defs>
          <filter id="poster-grade" colorInterpolationFilters="sRGB">
            <feColorMatrix type="saturate" values="0" />
            <feComponentTransfer>
              <feFuncR type="table" tableValues="0 0.02 0.1 0.55 0.92 1" />
              <feFuncG type="table" tableValues="0 0.02 0.1 0.55 0.92 1" />
              <feFuncB type="table" tableValues="0 0.02 0.1 0.55 0.92 1" />
            </feComponentTransfer>
          </filter>
          <filter id="poster-grain">
            <feTurbulence
              type="fractalNoise"
              baseFrequency="0.9"
              numOctaves="2"
              stitchTiles="stitch"
            />
            <feColorMatrix
              type="matrix"
              values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.55 0"
            />
          </filter>
        </defs>
      </svg>

      <main className={styles.poster}>
        <img
          src={content.portraitSrc}
          alt=""
          aria-hidden="true"
          className={styles.portraitBg}
          draggable={false}
        />

        <div className={styles.stage}>
          <img
            src={content.portraitSrc}
            alt={content.portraitAlt}
            className={styles.portrait}
            draggable={false}
          />

          <div className={styles.darkWash} aria-hidden="true" />

          <nav className={styles.nav}>
            <div className={styles.brandGroup}>
              <span className={styles.brandMono}>{content.brand.mono}</span>
              <span className={styles.brandMark}>
                <span className={styles.brandCopy}>©</span>
                {content.brand.mark}
              </span>
            </div>
            <ul className={styles.navItems}>
              {content.nav.map((item) => (
                <li key={item.label}>
                  <Link to={item.to} className={styles.navLink}>
                    {item.label}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>

          <div className={styles.bannerGroup}>
            <div className={styles.banner}>
              <span className={styles.bannerWord}>{content.bannerLeft}</span>
              <span className={styles.bannerWord}>{content.bannerRight}</span>
            </div>
            <p className={styles.bannerBody}>{content.bannerBody}</p>
          </div>

          <div className={styles.redBlock} aria-hidden="true" />
          <h1 className={styles.headline}>
            <span className={styles.headlineInner}>{content.headline}</span>
          </h1>

          <p className={styles.bodyLeft}>{content.bodyLeft}</p>
          <p className={styles.bodyRight}>{content.bodyRight}</p>

          <footer className={styles.footer}>
            <a
              className={styles.footerLeft}
              href={content.footerHref}
              target="_blank"
              rel="noreferrer noopener"
            >
              {content.footerLeft}
            </a>
            <span className={styles.footerRight}>
              <span className={styles.footerDash}>&mdash;</span>
              <span className={styles.footerNumber}>
                {content.footerNumber}
              </span>
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

Component.displayName = 'Landing'
