// ===================
// © AngelaMos | 2026
// index.tsx
// ===================

import { type ReactElement, useEffect, useRef, useState } from 'react'
import type { IconType } from 'react-icons'
import {
  FaArrowRightLong,
  FaEnvelope,
  FaFacebookF,
  FaInstagram,
  FaLinkedinIn,
  FaThreads,
  FaTiktok,
  FaXTwitter,
  FaYoutube,
} from 'react-icons/fa6'
import { useLiveFollowers } from '@/api'
import styles from './work-with-me.module.scss'

type Channel = {
  key: string
  label: string
  short: string
  Icon: IconType
}

const CHANNELS: Record<string, Channel> = {
  instagram: { key: 'instagram', label: 'Instagram', short: 'IG', Icon: FaInstagram },
  threads: { key: 'threads', label: 'Threads', short: 'TH', Icon: FaThreads },
  x: { key: 'x', label: 'X', short: 'X', Icon: FaXTwitter },
  linkedin: { key: 'linkedin', label: 'LinkedIn', short: 'LI', Icon: FaLinkedinIn },
  tiktok: { key: 'tiktok', label: 'TikTok', short: 'TT', Icon: FaTiktok },
  youtube: { key: 'youtube', label: 'YouTube', short: 'YT', Icon: FaYoutube },
  facebook: { key: 'facebook', label: 'Facebook', short: 'FB', Icon: FaFacebookF },
}

const DIRECT: { key: string; label: string; Icon: IconType; href: string }[] = [
  { key: 'instagram', label: 'Instagram — @carterperez.dev', Icon: FaInstagram, href: 'https://www.instagram.com/carterperez.dev' },
  { key: 'x', label: 'X', Icon: FaXTwitter, href: 'https://x.com/suuci2' },
  { key: 'tiktok', label: 'TikTok', Icon: FaTiktok, href: 'https://www.tiktok.com/@certgames.com' },
  { key: 'linkedin', label: 'LinkedIn', Icon: FaLinkedinIn, href: 'https://www.linkedin.com/in/carterperez-dev/' },
  { key: 'facebook', label: 'Facebook', Icon: FaFacebookF, href: 'https://www.facebook.com/profile.php?id=61573645016955' },
  { key: 'email', label: 'Email', Icon: FaEnvelope, href: 'mailto:carterperez@angelamos.com' },
]

const OFFERS: {
  id: string
  name: string
  price: string
  tag: string | null
  line: string
  items: string[]
  channels: string[]
}[] = [
  {
    id: '01',
    name: 'Single-Channel Drop',
    price: '3,500',
    tag: null,
    line: 'Native feed.',
    items: ['Instagram Reel', 'Instagram Story', 'Comment-to-DM funnel'],
    channels: ['instagram'],
  },
  {
    id: '02',
    name: 'Full Distribution',
    price: '4,000',
    tag: '+$500 — MAX REACH',
    line: '7 surfaces.',
    items: [
      'Everything in Drop 01',
      'Reposted across six more channels',
      'One comment-to-DM funnel, everywhere',
    ],
    channels: ['instagram', 'threads', 'x', 'linkedin', 'tiktok', 'youtube', 'facebook'],
  },
]

const TICKER = [
  'RATES INCREASE SOON',
  'OPEN FOR BRAND DEALS',
  'IG | THREADS | X | LINKEDIN | TIKTOK | YOUTUBE | FACEBOOK',
  'ONE LINK — EVERYTHING',
  '@CARTERPEREZ.DEV',
]

function formatInt(n: number): string {
  return n.toLocaleString('en-US')
}

function formatSync(iso: string | undefined): string {
  if (!iso) return '——'
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return '——'
  const p = (x: number) => String(x).padStart(2, '0')
  return `${d.getUTCFullYear()}·${p(d.getUTCMonth() + 1)}·${p(d.getUTCDate())} ${p(d.getUTCHours())}:${p(d.getUTCMinutes())}Z`
}

function useCountUp(target: number | null): number {
  const [n, setN] = useState(0)
  const prev = useRef(0)
  const raf = useRef<number | undefined>(undefined)

  useEffect(() => {
    if (target == null) return
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (reduce) {
      prev.current = target
      setN(target)
      return
    }
    const from = prev.current
    const dur = 1700
    const start = performance.now()
    const step = (t: number) => {
      const p = Math.min(1, (t - start) / dur)
      const e = 1 - (1 - p) ** 3
      setN(Math.round(from + (target - from) * e))
      if (p < 1) {
        raf.current = requestAnimationFrame(step)
      } else {
        prev.current = target
      }
    }
    raf.current = requestAnimationFrame(step)
    return () => {
      if (raf.current) cancelAnimationFrame(raf.current)
    }
  }, [target])

  return n
}

export function Component(): ReactElement {
  const root = useRef<HTMLDivElement>(null)
  const { followers, isLive, stats, isLoading } = useLiveFollowers()

  const configured = stats?.configured ?? null
  const hasReal = followers != null && configured !== false
  const shown = useCountUp(hasReal ? followers : null)

  const feedState = hasReal ? (isLive ? 'live' : 'cached') : isLoading ? 'sync' : 'standby'

  const [reduce, setReduce] = useState(false)
  useEffect(() => {
    setReduce(window.matchMedia('(prefers-reduced-motion: reduce)').matches)
  }, [])

  useEffect(() => {
    const el = root.current
    if (!el) return
    const nodes = Array.from(el.querySelectorAll<HTMLElement>('[data-reveal]'))
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (reduce) {
      for (const n of nodes) n.classList.add(styles.in)
      return
    }
    const io = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            entry.target.classList.add(styles.in)
            io.unobserve(entry.target)
          }
        }
      },
      { threshold: 0.14, rootMargin: '0px 0px -7% 0px' }
    )
    for (const n of nodes) io.observe(n)
    return () => io.disconnect()
  }, [])

  return (
    <div className={styles.page} ref={root}>
      <header className={styles.masthead}>
        <span className={styles.mhId}>
          <b>CARTER&nbsp;PEREZ</b>
          <i>/ @carterperez.dev</i>
        </span>
        <span className={styles.mhDoc}>© Anglemos</span>
        <span className={styles.mhStatus} data-state={feedState}>
          <span className={styles.led} aria-hidden="true" />
          Available
        </span>
      </header>

      <div className={styles.rail} aria-hidden="true">
        <span>MEDIA KIT</span>
        <span className={styles.railLine} />
        <span>MMXXVI</span>
        <span className={styles.railLine} />
        <span>38°53′N 77°02′W</span>
      </div>

      <main className={styles.frame}>
        <section className={styles.hero}>
          <div className={styles.heroLeft}>
            <h1 className={styles.lede} data-reveal>
              <span className={styles.ledeRow}>ATTENTION</span>
              <span className={styles.ledeRow}>IS</span>
              <span className={`${styles.ledeRow} ${styles.glitch}`} data-text="MANUFACTURED">
                MANUFACTURED
              </span>
            </h1>
            <p className={styles.deck} data-reveal>
              Cybersecurity Software Engineer.
              I help people break into Tech and pass certfications.
              Check out my gamified cybersecurity learning website <b>CertGames.com</b>. Proud{' '}
              <b>OSS Enjoyer</b>. There is no limit to the larp - <b>Angelamos.com</b>.
            </p>
            <div className={styles.heroMeta} data-reveal>
              <span className={styles.chip} data-state={feedState}>
                <span className={styles.led} aria-hidden="true" />
                {feedState === 'live'
                  ? 'UP'
                  : feedState === 'cached'
                    ? 'SIGNAL CACHED'
                    : feedState === 'sync'
                      ? 'ACQUIRING SIGNAL'
                      : 'SIGNAL ARMED'}
              </span>
              <a className={styles.scrollCue} href="#rate-card">
                JUMP TO RATES <FaArrowRightLong aria-hidden="true" />
              </a>
            </div>
          </div>

          <aside className={styles.instrument} data-reveal>
            <img className={styles.orb} src="/wwm/halftone-orb.webp" alt="" aria-hidden="true" />
            <div className={styles.instHead}>
              <span>INSTAGRAM · LIVE FOLLOWERS</span>
              <span className={styles.instTag} data-state={feedState}>
                <span className={styles.led} aria-hidden="true" />
                {feedState === 'live'
                  ? 'LIVE'
                  : feedState === 'cached'
                    ? 'CACHED'
                    : feedState === 'sync'
                      ? 'SYNC'
                      : 'STANDBY'}
              </span>
            </div>
            <div className={styles.readout} data-on={hasReal}>
              <span className={styles.readSlots} aria-hidden="true" />
              <span className={styles.readNum}>{hasReal ? formatInt(shown) : '———,———'}</span>
            </div>
            <div className={styles.instFoot}>
              <span>{hasReal ? 'STREAMING OVER /API/WS' : 'AWAITING IG TOKEN'}</span>
              <span>SYNC {formatSync(stats?.updatedAt)}</span>
            </div>
            <span className={styles.cross} data-pos="br" aria-hidden="true" />
          </aside>

          <img className={styles.angel} src="/wwm/angel.jpg" alt="" aria-hidden="true" draggable={false} />
        </section>

        <div className={styles.tickerWrap} aria-hidden="true">
          <div className={styles.ticker}>
            {[0, 1].map((dup) => (
              <span className={styles.tickerRun} key={dup}>
                {TICKER.map((t) => (
                  <span className={styles.tickItem} key={t}>
                    {t}
                    <i className={styles.tickDot} />
                  </span>
                ))}
              </span>
            ))}
          </div>
        </div>

        <section className={styles.plate} aria-labelledby="op-h">
          <div className={styles.plateBar} data-reveal>
            <span className={styles.plateNo}>001</span>
            <h2 className={styles.plateTitle} id="op-h">
              Development
            </h2>
            <span className={styles.plateNote}>SOLO</span>
          </div>
          <div className={styles.opGrid}>
            <p className={styles.opIntro} data-reveal>
              I build stuff and like to make money.
            </p>
            <dl className={styles.spec} data-reveal>
              {[
                ['DISCIPLINE', 'Software Engineering · Cybersecurity · Design'],
                ['BASED', 'United States · Annapolis'],
              ].map(([k, v]) => (
                <div className={styles.specRow} key={k}>
                  <dt>{k}</dt>
                  <span className={styles.leader} aria-hidden="true" />
                  <dd>{v}</dd>
                </div>
              ))}
            </dl>
          </div>
        </section>

        <section className={styles.plate} aria-labelledby="room-h">
          <div className={styles.plateBar} data-reveal>
            <span className={styles.plateNo}>002</span>
            <h2 className={styles.plateTitle} id="room-h">
              My Audience
            </h2>
            <span className={styles.plateNote}>WHO IS ON THE OTHER SIDE OF THE LENS</span>
          </div>

          <div className={styles.roomGrid}>
            <figure className={styles.specimen} data-reveal>
              <img src="/wwm/nautilus.jpeg" alt="X-ray of a chambered nautilus shell" draggable={false} />
              <span className={styles.specReticle} aria-hidden="true" />
              <figcaption>
                <b>EXHIBIT · NAUTILUS</b>
                <span>Each chamber larger than the last. Growth, x-rayed.</span>
              </figcaption>
            </figure>

            <div className={styles.gauges}>
              <div className={styles.gauge} data-reveal>
                <div className={styles.gaugeHead}>
                  <span>GEOGRAPHY</span>
                  <b>UNITED STATES</b>
                </div>
                <div className={styles.bar}>
                  <span className={styles.barFill} style={{ width: '72%' }} />
                </div>
                <div className={styles.gaugeFoot}>
                  <span>PRIMARY — US</span>
                  <span>SECONDARY — UK · CA · IN</span>
                </div>
              </div>

              <div className={styles.gauge} data-reveal>
                <div className={styles.gaugeHead}>
                  <span>AGE BAND</span>
                  <b>25 — 34</b>
                </div>
                <div className={styles.axis}>
                  {['18', '24', '25', '34', '44', '54+'].map((t, i) => (
                    <span className={styles.axisTick} data-hot={i === 2 || i === 3} key={t}>
                      {t}
                    </span>
                  ))}
                  <span className={styles.axisBand} />
                </div>
                <div className={styles.gaugeFoot}>
                  <span>CORE BUYING-AGE</span>
                  <span>PEAK DENSITY</span>
                </div>
              </div>

              <div className={styles.gauge} data-reveal>
                <div className={styles.gaugeHead}>
                  <span>SKEW</span>
                  <b>~90% MALE</b>
                </div>
                <div className={styles.split}>
                  <span className={styles.splitM} style={{ width: '90%' }}>
                    M
                  </span>
                  <span className={styles.splitF}>F</span>
                </div>
                <div className={styles.gaugeFoot}>
                  <span>MALE 90</span>
                  <span>FEMALE 10</span>
                </div>
              </div>

              <div className={styles.telebar} data-reveal>
                <div className={styles.tele}>
                  <span>MEDIA PUBLISHED</span>
                  <b>{stats?.media != null ? formatInt(stats.media) : '——'}</b>
                </div>
                <div className={styles.tele}>
                  <span>ENGAGEMENT</span>
                  <b>22%</b>
                </div>
                <div className={styles.tele}>
                  <span>FEED</span>
                  <b data-state={feedState}>
                    <span className={styles.led} aria-hidden="true" />
                    {feedState === 'live' ? 'LIVE' : feedState === 'cached' ? 'CACHED' : feedState === 'sync' ? 'SYNC' : 'STANDBY'}
                  </b>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className={styles.plate} id="rate-card" aria-labelledby="rate-h">
          <div className={styles.plateBar} data-reveal>
            <span className={styles.plateNo}>PLATE 03</span>
            <h2 className={styles.plateTitle} id="rate-h">
              MY RATES
            </h2>
            <span className={styles.plateNote}>TWO WAYS YOU CAN MAKE MONEY</span>
          </div>

          <div className={styles.offers}>
            {OFFERS.map((o) => (
              <article className={styles.card} key={o.id} data-feature={o.id === '02'} data-reveal>
                <header className={styles.cardTop}>
                  <span className={styles.cardNo}>DROP {o.id}</span>
                  {o.tag ? <span className={styles.cardTag}>{o.tag}</span> : null}
                </header>
                <h3 className={styles.cardName}>{o.name}</h3>
                <div className={styles.price}>
                  <span className={styles.priceCur}>$</span>
                  <span className={styles.priceNum}>{o.price}</span>
                  <span className={styles.priceUnit}>USD</span>
                </div>
                <p className={styles.cardLine}>{o.line}</p>
                <ul className={styles.cardItems}>
                  {o.items.map((it) => (
                    <li key={it}>
                      <FaArrowRightLong aria-hidden="true" />
                      {it}
                    </li>
                  ))}
                </ul>
                <div className={styles.cardChannels}>
                  {o.channels.map((c) => {
                    const ch = CHANNELS[c]
                    const Icon = ch.Icon
                    return (
                      <span className={styles.channel} title={ch.label} key={c}>
                        <Icon aria-hidden="true" />
                      </span>
                    )
                  })}
                </div>
                <a
                  className={styles.cardCta}
                  href={`mailto:carterperez@angelamos.com?subject=${encodeURIComponent(`Brand deal — Drop ${o.id}`)}`}
                >
                  BOOK DROP {o.id} <FaArrowRightLong aria-hidden="true" />
                </a>
              </article>
            ))}

            <figure className={styles.koi} data-reveal>
              <img src="/wwm/koi.webp" alt="Two koi forming a circle" draggable={false} />
              <figcaption>EXHIBIT · KOI — UPSTREAM, ALWAYS</figcaption>
            </figure>
          </div>

        </section>

        <section className={styles.outro} aria-labelledby="out-h">
          <span className={styles.cross} data-pos="tl" aria-hidden="true" />
          <p className={styles.outroEy} data-reveal>
            THE ONE LINK
          </p>
          <h2 className={styles.outroH} id="out-h" data-reveal>
            ONE LINK.
            <br />
            EVERYTHING.
          </h2>
          <p className={styles.outroSub} data-reveal>
            Contact me — I read everything.
          </p>
          <div className={styles.outroCtas} data-reveal>
            <a className={styles.primary} href="mailto:carterperez@angelamos.com?subject=Brand%20deal">
              OPEN A LINE <FaArrowRightLong aria-hidden="true" />
            </a>
            <a className={styles.secondary} href="https://www.instagram.com/carterperez.dev" target="_blank" rel="noreferrer noopener">
              DM ON INSTAGRAM
            </a>
          </div>
          <ul className={styles.directLines} data-reveal>
            {DIRECT.map(({ key, label, Icon, href }) => (
              <li key={key}>
                <a href={href} aria-label={label} title={label} target={href.startsWith('http') ? '_blank' : undefined} rel={href.startsWith('http') ? 'noreferrer noopener' : undefined}>
                  <Icon aria-hidden="true" />
                </a>
              </li>
            ))}
          </ul>
        </section>

        <footer className={styles.colophon}>
          <span>© ANGELAMOS · CARTER PEREZ — 2026</span>
          <span>STAGE 1</span>
          <span>CRACKED</span>
        </footer>
      </main>

      <div className={styles.scan} aria-hidden="true" />
      <div className={styles.grain} aria-hidden="true">
        <svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" preserveAspectRatio="none">
          <filter id="wwm-grain">
            <feTurbulence type="turbulence" baseFrequency="1.55" numOctaves="1" seed="2" stitchTiles="stitch">
              {reduce ? null : (
                <animate attributeName="seed" from="0" to="100" dur="3.17s" repeatCount="indefinite" />
              )}
            </feTurbulence>
          </filter>
          <rect width="100%" height="100%" filter="url(#wwm-grain)" />
        </svg>
      </div>
    </div>
  )
}

Component.displayName = 'WorkWithMe'
