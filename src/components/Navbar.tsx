'use client'

import Link from 'next/link'

export default function Navbar() {
  return (
    <header className="site-header">
      <Link className="brand" href="/" aria-label="Karriko Startseite">
        <span className="brand-mark">K</span>
        <span>Karriko</span>
      </Link>

      <nav className="main-nav" aria-label="Hauptnavigation">
        <Link href="/#bewertungen">Bewertungen</Link>
        <Link href="/unternehmen">Betriebe</Link>
        <Link href="/datenschutz">Datenschutz</Link>
      </nav>

      <Link className="header-action" href="/login">
        Anmelden
      </Link>
    </header>
  )
}
