/**
 * Analytics
 * 
 * Route: /analytics
 * Rendering: SSR + CSR (Charts)
 * 
 * Widgets:
 * - Gesamtbewertung Verlauf (7/30/90 Tage)
 * - Bewertungsanzahl (7/30/90 Tage)
 * - Kategorie-Scores (Radardiagramm)
 * - Profilaufrufe (7/30 Tage)
 * - Branchenvergleich (Premium only)
 * 
 * Datenschutz:
 * - Aggregierte Daten (keine personenbezogenen Daten)
 * - Profilaufrufe ohne Nutzer-Identifikation
 */

export const metadata = {
  title: 'Analytics - Karriko Betrieb',
  description: 'Deine Analytics und Statistiken'
}

export default function BetriebAnalyticsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Analytics</h1>

      {/* Time Range Selector */}
      <div className="mb-8 flex gap-4">
        {/* TODO: Time range buttons (7d, 30d, 90d) */}
      </div>

      <div className="space-y-8">
        {/* Overall Rating Trend */}
        <section className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-bold mb-4">Gesamtbewertung Verlauf</h2>
          {/* TODO: Line chart */}
        </section>

        {/* Review Count */}
        <section className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-bold mb-4">Neue Bewertungen</h2>
          {/* TODO: Bar chart */}
        </section>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Category Scores */}
          <section className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Kategorie-Scores</h2>
            {/* TODO: Radar chart with 5 categories */}
          </section>

          {/* Profile Views */}
          <section className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Profilaufrufe</h2>
            {/* TODO: Line chart */}
          </section>
        </div>

        {/* Industry Comparison (Premium) */}
        <section className="bg-blue-50 p-6 rounded-lg border border-blue-200">
          <h2 className="text-xl font-bold mb-2">🔒 Branchenvergleich</h2>
          <p className="text-sm text-blue-700 mb-4">
            Diese Funktion ist nur im Premium-Plan verfügbar. 
            <a href="/subscription" className="font-bold underline">Jetzt upgraden</a>
          </p>
        </section>
      </div>

      {/* Privacy Notice */}
      <div className="mt-8 p-4 bg-gray-50 rounded text-sm text-gray-600">
        ℹ️ Analytics-Daten sind aggregiert und enthalten keine personenbezogenen Daten.
      </div>
    </div>
  )
}
