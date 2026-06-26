/**
 * Allgemeine Geschäftsbedingungen (AGB)
 * 
 * Route: /agb
 * Rendering: SSG
 * 
 * PFLICHT: Vor Go-Live rechtlich prüfen lassen!
 */

export const metadata = {
  title: 'AGB - Karriko',
  description: 'Allgemeine Geschäftsbedingungen von Karriko'
}

export default function TermsPage() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-3xl">
      <h1 className="text-4xl font-bold mb-8">Allgemeine Geschäftsbedingungen</h1>

      <div className="prose prose-lg max-w-none">
        <h2>1. Geltungsbereich</h2>
        <p>
          Beschreibe hier den räumlichen und sachlichen Geltungsbereich der Bedingungen sowie die betroffenen Nutzergruppen.
        </p>

        <h2>2. Vertragsgegenstand</h2>
        <p>
          Lege hier die angebotenen Funktionen, Leistungen und Leistungsgrenzen der Plattform fest.
        </p>

        <h2>3. Registrierung und Nutzerkonto</h2>
        <p>
          Definiere hier die Voraussetzungen für Registrierung, Kontosicherheit und den Umgang mit Zugangsdaten.
        </p>

        <h2>4. Nutzerverhalten und Inhalte</h2>
        <p>
          Beschreibe hier Regeln für zulässige Inhalte, Missbrauch, Sperrung und Moderation.
        </p>

        <h2>5. Bewertungen</h2>
        <p>
          Erkläre hier die Grundsätze für Bewertungen, Verifikation, Veröffentlichung und Missbrauchskontrollen.
        </p>

        <h2>6. Freistellung und Haftung</h2>
        <p>
          Nenne hier die Haftungsgrenzen, Ausschlüsse und mögliche Freistellungsansprüche.
        </p>

        <h2>7. Freemium und Premium Services</h2>
        <p>
          Falls Premium-Angebote geplant sind, beschreibe hier Unterschiede, Preise und Laufzeiten.
        </p>

        <h2>8. Kündigung und Sperrung</h2>
        <p>
          Regel hier, unter welchen Bedingungen Konten gekündigt, gesperrt oder gelöscht werden können.
        </p>

        <h2>9. Änderungen der AGB</h2>
        <p>
          Definiere hier, wie Änderungen angekündigt werden und wann sie wirksam werden.
        </p>

        <h2>10. Schlussbestimmungen</h2>
        <p>
          Ergänze hier anwendbares Recht, Gerichtsstand und sonstige Schlussbestimmungen.
        </p>

        <p className="mt-8 pt-8 border-t text-sm text-gray-600">
          ⚠️ <strong>WICHTIG:</strong> Diese AGB müssen vor Go-Live von einem Rechtsanwalt geprüft werden!
        </p>
      </div>
    </div>
  )
}
