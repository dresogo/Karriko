/**
 * Über uns Seite
 * 
 * Route: /ueber-uns
 * Rendering: SSG
 */

export const metadata = {
  title: 'Über uns - Karriko',
  description: 'Erfahre mehr über Karriko und unser Team'
}

export default function AboutPage() {
  return (
    <div className="space-y-16">
      {/* Hero */}
      <section className="bg-gradient-to-r from-emerald-600 to-emerald-700 text-white py-16">
        <div className="container mx-auto px-4 text-center">
          <h1 className="text-4xl font-bold mb-4">Über Karriko</h1>
          <p className="text-lg">Unsere Mission: Die beste Bewertungsplattform für Ausbildungsbetriebe im DACH-Raum</p>
        </div>
      </section>

      {/* Mission & Vision */}
      <section className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
          <div>
            <h2 className="text-2xl font-bold mb-4">Mission</h2>
            {/* TODO: Mission text */}
          </div>
          <div>
            <h2 className="text-2xl font-bold mb-4">Vision</h2>
            {/* TODO: Vision text */}
          </div>
        </div>
      </section>

      {/* Team */}
      <section className="bg-gray-50 py-16">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">Unser Team</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* TODO: Team member cards */}
          </div>
        </div>
      </section>

      {/* Contact */}
      <section className="container mx-auto px-4">
        <h2 className="text-2xl font-bold mb-4">Kontakt</h2>
        {/* TODO: Contact info */}
      </section>
    </div>
  )
}
