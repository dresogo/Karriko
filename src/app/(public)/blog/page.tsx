/**
 * Blog Übersicht
 * 
 * Route: /blog
 * Rendering: SSG
 * 
 * Inhalt:
 * - Blog-Artikel Übersicht
 * - Kategorien: Azubis, Betriebe, Markt
 * - Suchfunktion
 */

export const metadata = {
  title: 'Blog - Karriko',
  description: 'Tipps und Guides für Auszubildende und Betriebe'
}

export default function BlogPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-4xl font-bold mb-4">Blog & Ratgeber</h1>
      <p className="text-lg text-gray-600 mb-8">Tipps und Insights für deine Karriere</p>

      {/* Categories / Search */}
      <div className="mb-12">
        {/* TODO: Category tabs */}
        {/* TODO: Search input */}
      </div>

      {/* Article Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {/* TODO: Article cards */}
      </div>
    </div>
  )
}
