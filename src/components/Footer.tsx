import Link from 'next/link'

export default function Footer() {
  return (
    <footer className="border-t border-[#e5e7eb] bg-white">
      <div className="mx-auto max-w-7xl px-8 py-12">
        <div className="grid grid-cols-1 gap-10 sm:grid-cols-2 lg:grid-cols-4">
          {/* Brand */}
          <div>
            <div className="font-serif-display text-xl text-[#111827]">
              Karriko
            </div>
            <div className="mt-2 text-xs text-[#9ca3af] uppercase tracking-wider">
              © 2024 Karriko. The Transparent Curator
            </div>
          </div>

          {/* Rechtliches */}
          <div>
            <p className="text-xs font-bold uppercase tracking-wider text-[#374151]">Rechtliches</p>
            <ul className="mt-4 space-y-2.5">
              <li>
                <Link href="/impressum" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  Impressum
                </Link>
              </li>
              <li>
                <Link href="/datenschutz" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  Datenschutz
                </Link>
              </li>
              <li>
                <Link href="/agb" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  AGB
                </Link>
              </li>
            </ul>
          </div>

          {/* Plattform */}
          <div>
            <p className="text-xs font-bold uppercase tracking-wider text-[#374151]">Plattform</p>
            <ul className="mt-4 space-y-2.5">
              <li>
                <Link href="/jobs" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  Job Market
                </Link>
              </li>
              <li>
                <Link href="/company" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  Unternehmen
                </Link>
              </li>
              <li>
                <Link href="/" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  Community
                </Link>
              </li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <p className="text-xs font-bold uppercase tracking-wider text-[#374151]">Support</p>
            <ul className="mt-4 space-y-2.5">
              <li>
                <Link href="/hilfe" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  Hilfe Center
                </Link>
              </li>
              <li>
                <Link href="/kontakt" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  Kontakt
                </Link>
              </li>
              <li>
                <Link href="/accessibility" className="text-xs text-[#6b7280] uppercase tracking-wider transition hover:text-[#1a3a2a]">
                  Accessibility
                </Link>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </footer>
  )
}
