// ===================
// © AngelaMos | 2026
// instruments.ts
// ===================

export interface Instrument {
  no: string
  name: string
  lang: string
  desc: string
  path: string
}

export const INSTRUMENTS: Instrument[] = [
  {
    no: '01',
    name: 'angela',
    lang: 'PYTHON',
    desc: 'Walks your dependency tree, cross-checks the advisory feeds, and rewrites the lockfile around whatever is quietly bleeding.',
    path: '',
  },
  {
    no: '02',
    name: 'docksec',
    lang: 'GO',
    desc: 'Audits a running Docker host against the CIS Benchmark and prints the gaps the way an attacker would read them.',
    path: 'docksec',
  },
  {
    no: '03',
    name: 'portia',
    lang: 'GO',
    desc: 'Crawls a repo and its entire git history for secrets, with the file, line, and commit that leaked them.',
    path: 'portia',
  },
  {
    no: '04',
    name: 'cre',
    lang: 'CRYSTAL',
    desc: 'Holds every vault and secret manager to one rotation policy. Expiry is not a suggestion.',
    path: 'cre',
  },
  {
    no: '05',
    name: 'hashcracker',
    lang: 'C',
    desc: 'Dictionary, rule-mutation, and raw brute force across every core you give it. Feed it a digest, come back to plaintext.',
    path: 'hashcracker',
  },
  {
    no: '06',
    name: 'tlsfp',
    lang: 'GO',
    desc: 'Fingerprints a TLS handshake, JA3 and JA4, and flags the client lying about what it is.',
    path: 'tlsfp',
  },
  {
    no: '07',
    name: 'certscout',
    lang: 'C · NCURSES',
    desc: 'Scrapes and ranks the job market for the security certifications that actually move the needle.',
    path: 'certscout',
  },
  {
    no: '08',
    name: 'yoshi-audit',
    lang: 'GO · TUI',
    desc: 'A retro TUI that watches the whole machine and prunes the processes and Docker layers rotting in the background.',
    path: 'yoshi-audit',
  },
  {
    no: '09',
    name: 'trash-gui',
    lang: 'C++ · QT6',
    desc: 'A KDE trash manager that deletes with intent. Privileged removal through polkit. What goes in does not come back.',
    path: 'trash-gui',
  },
  {
    no: '10',
    name: 'erhm',
    lang: 'ZIG',
    desc: 'A zero-dependency Reddit research miner. Point it at a set of subs and it pulls out the threads worth reading.',
    path: 'erhm',
  },
  {
    no: '11',
    name: '3d',
    lang: 'PYTHON · CUDA',
    desc: 'A GPU-accelerated 3D voice assistant. Speak to it and it answers in space.',
    path: '3d',
  },
  {
    no: '12',
    name: 'zingela',
    lang: 'ZIG',
    desc: 'A stateless mass TCP and UDP scanner. One static binary, no connection table, no mercy.',
    path: 'zingela',
  },
  {
    no: '13',
    name: 'rveng',
    lang: 'DOCKER',
    desc: 'A self-hosted reverse-engineering learning platform. Installs, builds, and opens in your browser.',
    path: 'rveng',
  },
  {
    no: '14',
    name: 'nadezhda',
    lang: 'GO',
    desc: 'Security news and CVE intelligence in your terminal. Keyless by default.',
    path: 'nadezhda',
  },
  {
    no: '15',
    name: 'crypha',
    lang: 'GO',
    desc: 'Hides an encrypted payload inside an image, audio, QR code, text, or PDF.',
    path: 'crypha',
  },
  {
    no: '16',
    name: 'lisdex',
    lang: 'RUST',
    desc: 'A keyless memory-corruption scanner for C and C++ parsers.',
    path: 'lisdex',
  },
  {
    no: '17',
    name: 'erinyes',
    lang: 'GO',
    desc: 'Hunts obfuscated malware hiding in open source against a YAML signature catalog. Scan a checkout with zero network calls, retrohunt code search, or sweep every file a target owns.',
    path: 'erinyes',
  },
]
