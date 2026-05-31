// ===================
// © AngelaMos | 2026
// index.tsx
// ===================

import { type ReactElement, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ROUTES } from '@/config'
import styles from './contact.module.scss'

const RECIPIENT = 'contact@angelamos.com'

const content = {
  brand: {
    mono: 'AM',
    mark: '©ANGELAMOS',
  },
  nav: [
    { label: 'INDEX', href: null, to: ROUTES.INDEX, current: false },
    { label: 'ARCHIVE', href: null, to: ROUTES.ARCHIVE, current: false },
    { label: 'CONTACT', href: null, to: ROUTES.CONTACT, current: true },
  ],
  plate: '03',
  title: 'audience',
  intro:
    'TO BE HEARD HERE IS NOT PROMISED. SPEAK INTO IT ANYWAY — WHAT IS SAID INTO THE DARK STILL LEAVES A SHAPE.',
  specimen: {
    src: '/assets/lily.webp',
    alt: 'X-ray calla lily specimen',
    label: 'CALLA · LILIUM',
    caption:
      'A NEGATIVE PORTRAIT OF WHAT ONCE LIVED INSIDE IT. WHAT YOU SEE THROUGH IS THE PART ALREADY GONE.',
    plate: 'PLATE Nº 03 — DEVELOPED FROM ABSENCE',
  },
  ghostSrc: '/assets/jellyfish.jpg',
  sentLead: 'sent',
  sentBody: 'The request is made. The rest is not yours.',
  footerLeft: 'CarterPerez-dev / 2026',
  stamp: '38°53′N 77°02′W',
  date: '2026·05·30',
}

export function Component(): ReactElement {
  const [who, setWho] = useState('')
  const [where, setWhere] = useState('')
  const [what, setWhat] = useState('')
  const [sent, setSent] = useState(false)

  const mailto = useMemo(() => {
    const subject = who.trim() ? `An audience — ${who.trim()}` : 'An audience'
    const body = [
      who.trim() ? `I am ${who.trim()}.` : 'I am someone.',
      where.trim() ? `What is left of me answers to ${where.trim()}.` : '',
      what.trim() ? `I came here to say:\n${what.trim()}` : '',
    ]
      .filter(Boolean)
      .join('\n\n')
    return `mailto:${RECIPIENT}?subject=${encodeURIComponent(
      subject,
    )}&body=${encodeURIComponent(body)}`
  }, [who, where, what])

  const canSend =
    who.trim() !== '' && where.trim() !== '' && what.trim() !== ''

  function request(): void {
    if (!canSend) return
    window.location.href = mailto
    setSent(true)
  }

  return (
    <div className={styles.page}>
      <svg className={styles.svgDefs} aria-hidden="true">
        <defs>
          <filter id="audience-grade" colorInterpolationFilters="sRGB">
            <feColorMatrix type="saturate" values="0.12" />
            <feComponentTransfer>
              <feFuncR type="table" tableValues="0 0.03 0.12 0.5 0.88 1" />
              <feFuncG type="table" tableValues="0 0.03 0.12 0.5 0.88 1" />
              <feFuncB type="table" tableValues="0 0.04 0.14 0.54 0.92 1" />
            </feComponentTransfer>
          </filter>
          <filter id="audience-grain">
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

      <main className={styles.poster}>
        <img
          src={content.ghostSrc}
          alt=""
          aria-hidden="true"
          className={styles.ghost}
          draggable={false}
        />

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

          <figure className={styles.specimen}>
            <div className={styles.specimenFrame}>
              <img
                src={content.specimen.src}
                alt={content.specimen.alt}
                className={styles.specimenImg}
                draggable={false}
              />
              <span className={styles.reticle} aria-hidden="true" />
              <span className={styles.tick} aria-hidden="true" />
            </div>
            <figcaption className={styles.specimenMeta}>
              <span className={styles.specimenLabel}>
                {content.specimen.label}
              </span>
              <span className={styles.specimenCaption}>
                {content.specimen.caption}
              </span>
              <span className={styles.specimenPlate}>
                {content.specimen.plate}
              </span>
            </figcaption>
          </figure>

          <div className={styles.composition}>
            <div className={styles.head}>
              <span className={styles.eyebrow}>
                NO.&nbsp;{content.plate}&nbsp;—&nbsp;CORRESPONDENCE
              </span>
              <h1 className={styles.title}>
                <span className={styles.titleInner}>{content.title}</span>
              </h1>
              <p className={styles.intro}>{content.intro}</p>
            </div>

            {sent ? (
              <div className={styles.sent} role="status">
                <span className={styles.sentLead}>{content.sentLead}</span>
                <p className={styles.sentBody}>{content.sentBody}</p>
              </div>
            ) : (
              <form
                className={styles.letter}
                onSubmit={(e) => {
                  e.preventDefault()
                  request()
                }}
              >
                <p className={styles.line}>
                  <span className={styles.word}>I am</span>
                  <input
                    className={styles.fill}
                    value={who}
                    onChange={(e) => setWho(e.target.value)}
                    placeholder="who is asking"
                    aria-label="Your name"
                    autoComplete="name"
                  />
                  <span className={styles.word}>.</span>
                </p>
                <p className={styles.line}>
                  <span className={styles.word}>What is left of me answers to</span>
                  <input
                    className={`${styles.fill} ${styles.fillWide}`}
                    value={where}
                    onChange={(e) => setWhere(e.target.value)}
                    placeholder="where to return the answer"
                    aria-label="Your email or address"
                    inputMode="email"
                    autoComplete="email"
                  />
                  <span className={styles.word}>.</span>
                </p>
                <p className={styles.line}>
                  <span className={styles.word}>And I came here to say</span>
                </p>
                <textarea
                  className={styles.fillBlock}
                  value={what}
                  onChange={(e) => setWhat(e.target.value)}
                  placeholder="…"
                  aria-label="Your message"
                  rows={2}
                />

                <div className={styles.send}>
                  <button
                    type="submit"
                    className={styles.request}
                    disabled={!canSend}
                  >
                    REQUEST AN AUDIENCE
                  </button>
                  <span className={styles.sendNote}>
                    {canSend ? 'SEALED' : 'UNFINISHED'}
                  </span>
                </div>
              </form>
            )}
          </div>

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

Component.displayName = 'Contact'
