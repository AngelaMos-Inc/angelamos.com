// ===================
// © AngelaMos | 2026
// index.tsx
// ===================

import { type ReactElement, useState } from 'react'
import type { IconType } from 'react-icons'
import {
  FaDiscord,
  FaEnvelope,
  FaFacebookF,
  FaGithub,
  FaInstagram,
  FaLinkedinIn,
  FaPhone,
  FaTelegram,
  FaTiktok,
  FaXTwitter,
} from 'react-icons/fa6'
import { Link } from 'react-router-dom'
import { toast } from 'sonner'
import { useSubmitContact } from '@/api'
import { ROUTES } from '@/config'
import styles from './contact.module.scss'

type LineLink = {
  key: string
  label: string
  Icon: IconType
  href?: string
  copy?: string
}

const links: LineLink[] = [
  {
    key: 'instagram',
    label: 'Instagram',
    Icon: FaInstagram,
    href: 'https://www.instagram.com/carrterperez.dev',
  },
  {
    key: 'tiktok',
    label: 'TikTok',
    Icon: FaTiktok,
    href: 'https://www.tiktok.com/@certgames.com',
  },
  { key: 'x', label: 'X', Icon: FaXTwitter, href: 'https://x.com/suuci2' },
  {
    key: 'github',
    label: 'GitHub',
    Icon: FaGithub,
    href: 'https://github.com/CarterPerez-dev',
  },
  {
    key: 'linkedin',
    label: 'LinkedIn',
    Icon: FaLinkedinIn,
    href: 'https://www.linkedin.com/in/carterperez-dev/',
  },
  {
    key: 'facebook',
    label: 'Facebook',
    Icon: FaFacebookF,
    href: 'https://www.facebook.com/profile.php?id=61573645016955',
  },
  {
    key: 'telegram',
    label: 'Telegram',
    Icon: FaTelegram,
    href: 'https://t.me/carterperez_dev',
  },
  {
    key: 'discord',
    label: 'Discord — carter.perez.dev (copy)',
    Icon: FaDiscord,
    copy: 'carter.perez.dev',
  },
  {
    key: 'email',
    label: 'carterperez@angelamos.com',
    Icon: FaEnvelope,
    href: 'mailto:carterperez@angelamos.com',
  },
  {
    key: 'phone',
    label: '410-212-7288',
    Icon: FaPhone,
    href: 'tel:+14102127288',
  },
]

const content = {
  brand: {
    mono: 'AM',
    mark: 'ANGELAMOS',
  },
  nav: [
    { label: 'COMPANY', to: ROUTES.COMPANY, current: false },
    { label: 'INDEX', to: ROUTES.INDEX, current: false },
    { label: 'CONTACT', to: ROUTES.CONTACT, current: true },
  ],
  plate: '03',
  title: 'audience',
  intro:
    "I read everything. If I don't reply, it wasn't worth one. Reflect on that.",
  specimen: {
    src: '/assets/lily.webp',
    alt: 'X-ray calla lily specimen',
    label: 'CALLA · LILIUM',
  },
  ghostSrc: '/assets/jellyfish.jpg',
  sentLead: 'sent',
  sentBody:
    "It's through. I read everything that lands here — I'll answer when it reaches me.",
  linesLabel: 'DIRECT LINES',
  footerLeft: 'CarterPerez.dev / 2026',
  footerHref: 'https://lisdex.sh',
  stamp: '38°53′N 77°02′W',
  date: '2026·05·30',
}

export function Component(): ReactElement {
  const [who, setWho] = useState('')
  const [where, setWhere] = useState('')
  const [what, setWhat] = useState('')
  const [sent, setSent] = useState(false)
  const submit = useSubmitContact()

  const canSend = who.trim() !== '' && where.trim() !== '' && what.trim() !== ''

  function request(): void {
    if (!canSend || submit.isPending) return
    submit.mutate(
      { name: who.trim(), replyTo: where.trim(), message: what.trim() },
      { onSuccess: () => setSent(true) }
    )
  }

  function copyHandle(value: string): void {
    void navigator.clipboard?.writeText(value)
    toast.success('Discord handle copied')
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
              <output className={styles.sent}>
                <span className={styles.sentLead}>{content.sentLead}</span>
                <p className={styles.sentBody}>{content.sentBody}</p>
              </output>
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
                    aria-label="Your name"
                    autoComplete="name"
                  />
                </p>
                <p className={styles.line}>
                  <span className={styles.word}>Reach me back at</span>
                  <input
                    className={`${styles.fill} ${styles.fillWide}`}
                    value={where}
                    onChange={(e) => setWhere(e.target.value)}
                    aria-label="Where to reach you"
                    autoComplete="email"
                  />
                </p>
                <p className={styles.line}>
                  <span className={styles.word}>I came here to say</span>
                </p>
                <textarea
                  className={styles.fillBlock}
                  value={what}
                  onChange={(e) => setWhat(e.target.value)}
                  placeholder="xx"
                  aria-label="Your message"
                  rows={1}
                />

                <div className={styles.send}>
                  <button
                    type="submit"
                    className={styles.request}
                    disabled={!canSend || submit.isPending}
                  >
                    {submit.isPending ? 'SENDING…' : 'REQUEST AN AUDIENCE'}
                  </button>
                  <span className={styles.sendNote}>
                    {submit.isPending
                      ? 'IN TRANSIT'
                      : canSend
                        ? 'SEALED'
                        : 'UNFINISHED'}
                  </span>
                </div>
              </form>
            )}

            <div className={styles.lines}>
              <span className={styles.linesLabel}>{content.linesLabel}</span>
              <ul className={styles.lineList}>
                {links.map(({ key, label, Icon, href, copy }) => (
                  <li key={key}>
                    {href ? (
                      <a
                        className={styles.lineLink}
                        href={href}
                        aria-label={label}
                        title={label}
                        target={href.startsWith('http') ? '_blank' : undefined}
                        rel={
                          href.startsWith('http')
                            ? 'noreferrer noopener'
                            : undefined
                        }
                      >
                        <Icon aria-hidden="true" />
                      </a>
                    ) : (
                      <button
                        type="button"
                        className={styles.lineLink}
                        aria-label={label}
                        title={label}
                        onClick={() => {
                          if (copy) copyHandle(copy)
                        }}
                      >
                        <Icon aria-hidden="true" />
                      </button>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <footer className={styles.footer}>
            <a
              className={styles.footerLeft}
              href={content.footerHref}
              target="_blank"
              rel="noreferrer noopener"
            >
              {content.footerLeft}
            </a>
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
