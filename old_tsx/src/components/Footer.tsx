import Link from 'next/link'

export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="site-footer-grid">
        <div>
          <p className="footer-title">Karriko</p>
          <p>Ausbildungsbetriebe bewerten, transparenter entscheiden.</p>
        </div>

        <div>
          <p className="footer-title">Rechtliches</p>
          <ul>
            <li>
              <Link href="/impressum">Impressum</Link>
            </li>
            <li>
              <Link href="/datenschutz">Datenschutz</Link>
            </li>
            <li>
              <Link href="/agb">AGB</Link>
            </li>
          </ul>
        </div>

        <div>
          <p className="footer-title">Plattform</p>
          <ul>
            <li>
              <Link href="/jobs">Jobs</Link>
            </li>
            <li>
              <Link href="/suche">Suche</Link>
            </li>
            <li>
              <Link href="/unternehmen">Unternehmen</Link>
            </li>
          </ul>
        </div>

        <div>
          <p className="footer-title">Support</p>
          <ul>
            <li>
              <Link href="/hilfe">Hilfe</Link>
            </li>
            <li>
              <Link href="/kontakt">Kontakt</Link>
            </li>
            <li>
              <Link href="/accessibility">Barrierefreiheit</Link>
            </li>
          </ul>
        </div>
      </div>
    </footer>
  )
}
