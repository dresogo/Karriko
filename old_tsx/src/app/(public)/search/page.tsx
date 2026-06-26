/**
 * Suche & Entdecken
 * 
 * Route: /search
 * Rendering: SSR
 * Query-Parameter: ?q=[suchbegriff]&branche=[slug]&ort=[plz]&sort=[score|reviews|name]
 * 
 * Sektionen:
 * - Suchleiste
 * - Filterleiste (Branche, Ort, Mindestbewertung, Sortierung)
 * - Ergebnisliste
 * - Karte (optional, V2)
 * - Leerer Zustand
 */

import { Suspense } from 'react'

interface SearchPageProps {
  searchParams: Promise<{
    q?: string
    branche?: string
    ort?: string
    sort?: 'score' | 'reviews' | 'name'
    page?: string
  }>
}

export const metadata = {
  title: 'Suche - Karriko',
  description: 'Suche und entdecke Ausbildungsbetriebe'
}

export default async function SearchPage({ searchParams }: SearchPageProps) {
  await searchParams

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Search Bar */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-4">Ausbildungsbetriebe finden</h1>
        {/* TODO: Search input with autocomplete */}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        {/* Filter Sidebar */}
        <aside className="lg:col-span-1">
          <div className="bg-white p-6 rounded-lg shadow">
            {/* TODO: Branche filter */}
            {/* TODO: Ort/PLZ filter */}
            {/* TODO: Mindestbewertung slider */}
            {/* TODO: Sorting options */}
          </div>
        </aside>

        {/* Results */}
        <main className="lg:col-span-3">
          <Suspense fallback={<div>Lädt...</div>}>
            {/* TODO: Company cards grid */}
          </Suspense>
        </main>
      </div>
    </div>
  )
}
