/**
 * Betriebs-Dashboard
 *
 * Route: /betrieb-dashboard
 * Rendering: SSR
 *
 * Zweck: Überblick über Kennzahlen, Bewertungen und Aktivitäten
 */

export const metadata = {
  title: 'Dashboard - Karriko Betrieb',
  description: 'Dein Betriebs-Dashboard'
}

export default function BetriebDashboardPage() {
  return (
    <div className="container mx-auto px-4 py-8 space-y-8">
      <div>
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="text-gray-600">Übersicht deines Betriebsprofils</p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        {/* TODO: KPI cards */}
      </div>

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
        <div className="space-y-8 lg:col-span-2">
          <section className="rounded-lg bg-white p-6 shadow">
            <h2 className="mb-4 text-xl font-bold">Aktuelle Bewertungen</h2>
            {/* TODO: Recent reviews list */}
          </section>

          <section className="rounded-lg bg-white p-6 shadow">
            <h2 className="mb-4 text-xl font-bold">Score-Verlauf (30 Tage)</h2>
            {/* TODO: Line chart with score history */}
          </section>

          <section className="rounded-lg bg-white p-6 shadow">
            <h2 className="mb-4 text-xl font-bold">Offene Bewerbungen</h2>
            {/* TODO: Applications grouped by position */}
          </section>
        </div>

        <aside className="space-y-6">
          <section className="rounded-lg bg-white p-6 shadow">
            <h3 className="mb-4 text-lg font-bold">Profil-Vollständigkeit</h3>
            {/* TODO: Progress bar showing profile completion */}
          </section>
        </aside>
      </div>
    </div>
  )
}