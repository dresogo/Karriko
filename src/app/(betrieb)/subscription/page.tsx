/**
 * Abonnement verwalten
 * 
 * Route: /subscription
 * Rendering: SSR
 * 
 * Inhalt:
 * - Plan-Übersicht (Free vs Premium)
 * - Upgrade-Button
 * - Rechnungen (Liste vergangener)
 * - Kündigung-Option
 * 
 * Freemium-Modell:
 * | Feature | Free | Premium |
 * |---------|------|---------|
 * | Öffentliches Profil | ✅ | ✅ |
 * | Auf Bewertungen antworten | ✅ | ✅ |
 * | Stellenanzeigen (max.) | 2 | Unbegrenzt |
 * | Branchenvergleich | ❌ | ✅ |
 * | Hervorgehobenes Profil | ❌ | ✅ |
 * | Analytics (erweitert) | ❌ | ✅ |
 * | Support-Priorität | Standard | Priorität |
 */

export const metadata = {
  title: 'Abonnement - Karriko Betrieb',
  description: 'Verwalte dein Abonnement'
}

export default function BetriebSubscriptionPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Abonnement</h1>

      {/* Current Plan */}
      <section className="mb-12">
        <h2 className="text-2xl font-bold mb-6">Dein aktueller Plan</h2>
        {/* TODO: Current plan display with features */}
      </section>

      {/* Plan Comparison */}
      <section className="mb-12">
        <h2 className="text-2xl font-bold mb-6">Pläne vergleichen</h2>
        {/* TODO: Pricing table (Free vs Premium) */}
      </section>

      {/* Invoices */}
      <section className="mb-12">
        <h2 className="text-2xl font-bold mb-6">Rechnungen</h2>
        {/* TODO: List of past invoices with download links */}
      </section>

      {/* Cancellation */}
      <section className="bg-gray-50 p-6 rounded-lg">
        <h3 className="text-lg font-bold mb-2">Abonnement kündigen</h3>
        <p className="text-gray-600 mb-4">
          Das Abonnement läuft bis zum Ende der aktuellen Abrechnungsperiode und wird dann automatisch beendet.
        </p>
        {/* TODO: Cancel button */}
      </section>
    </div>
  )
}
