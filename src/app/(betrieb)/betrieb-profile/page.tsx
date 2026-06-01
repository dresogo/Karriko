/**
 * Unternehmensprofil verwalten
 *
 * Route: /betrieb-profile
 * Rendering: SSR (initiale Daten) + CSR (Live-Preview)
 */

export const metadata = {
  title: 'Profil - Karriko Betrieb',
  description: 'Verwalte dein Betriebsprofil'
}

export default function BetriebProfilePage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="mb-8 text-3xl font-bold">Unternehmensprofil</h1>

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
        <div className="space-y-6">
          {/* TODO: Profile form fields */}
        </div>

        <aside className="lg:sticky lg:top-20">
          <div className="rounded-lg bg-white p-6 shadow">
            <h3 className="mb-4 text-lg font-bold">Vorschau</h3>
            {/* TODO: Real-time preview of company profile */}
          </div>
        </aside>
      </div>
    </div>
  )
}