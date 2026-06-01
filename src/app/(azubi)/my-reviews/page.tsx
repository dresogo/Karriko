/**
 * Meine Bewertungen
 * 
 * Route: /my-reviews
 * Rendering: SSR
 * 
 * Inhalt:
 * - Tabelle/Karten mit allen eigenen Bewertungen
 * - Spalten: Betrieb, Datum, Score, Anonymität, Aktionen
 * - Sortierung, Paginierung
 * 
 * Aktionen:
 * - Bearbeiten (nur Text-Antworten)
 * - Löschen (Soft Delete)
 * 
 * Löschlogik:
 * - Bewertung löschen → Gesamtscore des Betriebs wird neu berechnet
 * - Soft Delete (deleted_at)
 * - Betriebsantworten bleiben erhalten
 */

export const metadata = {
  title: 'Meine Bewertungen - Karriko',
  description: 'Verwalte deine Bewertungen'
}

export default function MyReviewsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Meine Bewertungen</h1>

      {/* Filters & Sorting */}
      <div className="mb-6 flex gap-4">
        {/* TODO: Sort dropdown (newest, oldest) */}
      </div>

      {/* Reviews List */}
      <div className="space-y-4">
        {/* TODO: Review cards with:
          - Company name + logo
          - Date
          - Score (stars)
          - Anonymity status
          - Edit button
          - Delete button
          - Company reply preview
        */}
      </div>

      {/* Empty state */}
      {/* TODO: "Du hast noch keine Bewertungen geschrieben" message */}
    </div>
  )
}
