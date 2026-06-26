/**
 * Meldungen einreichen
 * 
 * Route: /reports
 * Rendering: CSR (Formular)
 * 
 * Meldungs-Flow:
 * 1. Betrieb wählt Bewertung aus (aus /reviews)
 * 2. Formular mit Grund, Beschreibung, Screenshots
 * 3. Submit → moderation_reports Eintrag
 * 4. Bestätigung: "Meldung eingegangen, wir prüfen innerhalb von 5 Werktagen"
 * 
 * Rate Limiting:
 * - Max. 5 Meldungen pro Betrieb pro 24h
 * 
 * Gründe:
 * - FAKE: Gefälschte Bewertung
 * - OFFENSIVE: Beleidigung/Spam
 * - WRONG_COMPANY: Falscher Betrieb
 * - OTHER: Sonstiges
 */

export const metadata = {
  title: 'Meldungen - Karriko Betrieb',
  description: 'Melde verdächtige Bewertungen'
}

export default function BetriebReportsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Verdächtige Bewertungen melden</h1>

      <div className="max-w-2xl bg-white p-8 rounded-lg shadow">
        {/* TODO: Report form with:
          - Review selection
          - Report reason (dropdown)
          - Description (max 500 chars)
          - Screenshot uploads (max 2 files)
          - Submit button
        */}

        {/* Rate limit info */}
        <div className="mt-6 p-4 bg-yellow-50 rounded text-sm text-yellow-700">
          ⚠️ Maximal 5 Meldungen pro 24 Stunden. Missbrauch wird überprüft.
        </div>
      </div>

      {/* Guidelines */}
      <section className="mt-12 max-w-2xl">
        <h2 className="text-xl font-bold mb-4">Richtlinien für Meldungen</h2>
        <ul className="space-y-2 text-gray-700">
          <li>✅ Melde nur Bewertungen, die du für falsch oder unangemessen hältst</li>
          <li>✅ Gib konkrete Gründe an</li>
          <li>✅ Beweise (Screenshots) helfen bei der Prüfung</li>
          <li>❌ Bitte keine Meldungen von konkurrierenden Bewertungen</li>
          <li>❌ Missbrauch wird dokumentiert und kann zu Sperrung führen</li>
        </ul>
      </section>
    </div>
  )
}
