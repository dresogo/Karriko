import Link from 'next/link'

export default function Footer() {
  return (
    <footer className="bg-gray-800 text-white">
      <div className="max-w-7xl mx-auto py-12 px-4 sm:px-6 lg:py-16 lg:px-8">
        <div className="xl:grid xl:grid-cols-3 xl:gap-8">
          <div className="space-y-8 xl:col-span-1">
            <div className="text-2xl font-bold">Karriko</div>
            <p className="text-gray-400 text-base">
              Transparente Bewertungsplattform für Auszubildende und Ausbildungsbetriebe im DACH-Raum.
            </p>
          </div>
          <div className="mt-12 grid grid-cols-2 gap-8 xl:mt-0 xl:col-span-2">
            <div className="md:grid md:grid-cols-2 md:gap-8">
              <div>
                <h3 className="text-sm font-semibold text-gray-400 tracking-wider uppercase">
                  Plattform
                </h3>
                <ul className="mt-4 space-y-4">
                  <li>
                    <Link href="/search" className="text-base text-gray-300 hover:text-white">
                      Suche
                    </Link>
                  </li>
                  <li>
                    <Link href="/jobs" className="text-base text-gray-300 hover:text-white">
                      Ausbildungsplätze
                    </Link>
                  </li>
                  <li>
                    <Link href="/dashboard" className="text-base text-gray-300 hover:text-white">
                      Dashboard
                    </Link>
                  </li>
                </ul>
              </div>
              <div className="mt-12 md:mt-0">
                <h3 className="text-sm font-semibold text-gray-400 tracking-wider uppercase">
                  Unternehmen
                </h3>
                <ul className="mt-4 space-y-4">
                  <li>
                    <Link href="/company/dashboard" className="text-base text-gray-300 hover:text-white">
                      Firmenbereich
                    </Link>
                  </li>
                  <li>
                    <Link href="/admin" className="text-base text-gray-300 hover:text-white">
                      Admin
                    </Link>
                  </li>
                </ul>
              </div>
            </div>
            <div className="md:grid md:grid-cols-2 md:gap-8">
              <div>
                <h3 className="text-sm font-semibold text-gray-400 tracking-wider uppercase">
                  Rechtliches
                </h3>
                <ul className="mt-4 space-y-4">
                  <li>
                    <Link href="/impressum" className="text-base text-gray-300 hover:text-white">
                      Impressum
                    </Link>
                  </li>
                  <li>
                    <Link href="/datenschutz" className="text-base text-gray-300 hover:text-white">
                      Datenschutz
                    </Link>
                  </li>
                  <li>
                    <Link href="/agb" className="text-base text-gray-300 hover:text-white">
                      AGB
                    </Link>
                  </li>
                </ul>
              </div>
              <div className="mt-12 md:mt-0">
                <h3 className="text-sm font-semibold text-gray-400 tracking-wider uppercase">
                  Sprache
                </h3>
                <ul className="mt-4 space-y-4">
                  <li>
                    <span className="text-base text-white">Deutsch</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
        <div className="mt-12 border-t border-gray-700 pt-8">
          <p className="text-base text-gray-400 xl:text-center">
            &copy; 2026 Karriko. Alle Rechte vorbehalten.
          </p>
        </div>
      </div>
    </footer>
  )
}