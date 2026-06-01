/**
 * B2B Landing Page für Betriebe
 * 
 * Route: /fuer-betriebe
 * Rendering: SSG
 * 
 * Sektionen:
 * - Hero
 * - Features
 * - Pricing
 * - Social Proof
 * - FAQ
 * - CTA Footer
 */

export const metadata = {
  title: 'Für Betriebe - Karriko',
  description: 'Profil erstellen, Bewertungen verwalten, Azubis finden'
}

export default function ForCompaniesPage() {
  return (
    <div className="space-y-20">
      {/* Hero */}
      <section className="bg-gradient-to-r from-blue-600 to-blue-700 text-white py-20">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-5xl font-bold mb-4">Werden Sie sichtbar</h1>
          <p className="text-xl mb-8">Verwalten Sie Ihr Bewertungsprofil und finden Sie die besten Auszubildenden</p>
          {/* TODO: CTA Button */}
        </div>
      </section>

      {/* Features */}
      <section className="container mx-auto px-4">
        <h2 className="text-3xl font-bold text-center mb-12">Für Ihr Unternehmen</h2>
        {/* TODO: Feature cards */}
      </section>

      {/* Pricing */}
      <section className="bg-gray-50 py-16">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">Flexibles Preismodell</h2>
          {/* TODO: Pricing table - Free vs Premium */}
        </div>
      </section>

      {/* Social Proof */}
      <section className="container mx-auto px-4 text-center">
        <h2 className="text-3xl font-bold mb-8">Vertraut von Hunderten Betrieben</h2>
        {/* TODO: Stats */}
      </section>

      {/* FAQ */}
      <section className="container mx-auto px-4">
        <h2 className="text-3xl font-bold text-center mb-12">Häufig gestellte Fragen</h2>
        {/* TODO: FAQ accordion */}
      </section>

      {/* CTA Footer */}
      <section className="bg-emerald-600 text-white py-12">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-3xl font-bold mb-4">Starten Sie noch heute</h2>
          <p className="mb-8">Kostenlos und ohne Kreditkarte</p>
          {/* TODO: CTA Button */}
        </div>
      </section>
    </div>
  )
}
