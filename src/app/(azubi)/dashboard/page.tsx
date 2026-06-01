/**
 * Azubi-Dashboard
 * 
 * Route: /dashboard
 * Rendering: SSR
 * 
 * Zweck: Persönliche Übersicht, Einstiegspunkt nach Login
 * 
 * Sektionen:
 * - Begrüßung
 * - Aktivitäts-Feed
 * - Meine Bewertungen (letzte 3)
 * - Empfehlungen
 * - Merkliste (Vorschau)
 * - Benachrichtigungen
 */

export const metadata = {
  title: 'Dashboard - Karriko',
  description: 'Dein Azubi-Dashboard'
}

export default function AzubiDashboardPage() {
  return (
    <div className="container mx-auto px-4 py-8 space-y-8">
      {/* Welcome Banner */}
      <section className="bg-gradient-to-r from-emerald-500 to-emerald-600 text-white p-8 rounded-lg">
        <h1 className="text-4xl font-bold mb-2">Hallo [Vorname]! 👋</h1>
        <p className="text-emerald-100">Hier sind deine wichtigsten Updates</p>
      </section>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-8">
          {/* Activity Feed */}
          <section>
            <h2 className="text-2xl font-bold mb-4">Deine Aktivitäten</h2>
            {/* TODO: Activity feed component */}
          </section>

          {/* Recent Reviews */}
          <section>
            <h2 className="text-2xl font-bold mb-4">Meine Bewertungen</h2>
            {/* TODO: Recent reviews list */}
          </section>

          {/* Recommendations */}
          <section>
            <h2 className="text-2xl font-bold mb-4">Empfehlungen für dich</h2>
            {/* TODO: Recommended companies based on region/trade */}
          </section>
        </div>

        {/* Sidebar */}
        <aside className="space-y-6">
          {/* Bookmarks Preview */}
          <section className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-bold mb-4">Merkliste</h3>
            {/* TODO: Bookmark preview (first 3) */}
          </section>

          {/* Notifications */}
          <section className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-bold mb-4">Benachrichtigungen</h3>
            {/* TODO: Unread notifications badge */}
          </section>
        </aside>
      </div>
    </div>
  )
}
