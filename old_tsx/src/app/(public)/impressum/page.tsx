/**
 * Impressum
 * 
 * Route: /impressum
 * Rendering: SSG
 * 
 * Inhalt nach § 5 TMG:
 * - Verantwortlicher
 * - Anschrift
 * - E-Mail
 * - USt-ID
 */

export const metadata = {
  title: 'Impressum - Karriko',
  description: 'Impressum von Karriko'
}

export default function ImpressumPage() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-3xl">
      <h1 className="text-4xl font-bold mb-8">Impressum</h1>

      <div className="prose prose-lg max-w-none">
        <h2>Angaben gemäß § 5 TMG</h2>
        
        <h3>Verantwortlicher</h3>
        <p>
          Trage hier die vollständigen Angaben des Betreibers ein, einschließlich Name, Rechtsform, Anschrift, E-Mail und Telefonnummer.
        </p>

        <h3>USt-ID</h3>
        <p>
          Falls vorhanden, ergänze hier die Umsatzsteuer-Identifikationsnummer.
        </p>

        <h3>Vertreter</h3>
        <p>
          Wenn eine juristische Person Betreiber ist, nenne hier die vertretungsberechtigten Personen.
        </p>

        <h3>Kontakt</h3>
        <p>
          Hier gehören die direkten Kontaktmöglichkeiten des Verantwortlichen hinein.
        </p>

        <h3>Streitschlichtung</h3>
        <p>
          Ergänze hier die Hinweise zur Streitbeilegung und zur Teilnahme an Verbraucherschlichtungsverfahren.
        </p>
      </div>
    </div>
  )
}
