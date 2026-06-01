/**
 * Merkliste
 * 
 * Route: /bookmarks
 * Rendering: SSR
 * 
 * Inhalt:
 * - Grid aus CompanyCard-Komponenten
 * - Sortierung: Gespeichert-Datum, Name, Bewertung
 * - "Aus Merkliste entfernen"-Button pro Card
 * - Leerer Zustand
 */

export const metadata = {
  title: 'Meine Merkliste - Karriko',
  description: 'Deine gespeicherten Betriebe'
}

export default function BookmarksPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Meine Merkliste</h1>

      {/* Sorting */}
      <div className="mb-8">
        {/* TODO: Sort options (saved, name, rating) */}
      </div>

      {/* Company Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* TODO: Company cards with bookmarks */}
        {/* Each card should have:
          - Company logo + name
          - Rating
          - Location
          - Review count
          - Remove bookmark button
        */}
      </div>

      {/* Empty state */}
      {/* TODO: "Du hast noch keine Betriebe gespeichert" + Link to search */}
    </div>
  )
}
