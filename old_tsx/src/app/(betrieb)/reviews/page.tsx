/**
 * Bewertungen verwalten
 * 
 * Route: /reviews
 * Rendering: SSR + CSR (Antwort-Formular)
 * 
 * Layout:
 * - Filterleiste: Alle / Beantwortet / Unbeantwortet / Gemeldet
 * - Sortierung: Neueste / Älteste / Schlechteste / Beste
 * 
 * Pro Bewertung:
 * - Vollständige Darstellung
 * - Antwortfeld (max. 1 Antwort, nicht bearbeitbar nach Veröffentlichung)
 * - Melde-Button
 * 
 * Antwort-Regeln:
 * - Max. 1 Antwort pro Bewertung
 * - Max. 1000 Zeichen
 * - Plain Text (kein HTML/Links)
 * - Erscheint öffentlich unter der Bewertung
 */

export const metadata = {
  title: 'Bewertungen - Karriko Betrieb',
  description: 'Verwalte deine Bewertungen'
}

export default function BetriebReviewsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Bewertungen verwalten</h1>

      {/* Filter & Sort */}
      <div className="mb-6 flex flex-wrap gap-4">
        {/* TODO: Filter buttons (All, Answered, Unanswered, Reported) */}
        {/* TODO: Sort dropdown */}
      </div>

      {/* Reviews List */}
      <div className="space-y-6">
        {/* TODO: Review items with:
          - Reviewer info (name/anonymous, date)
          - Rating stars
          - Review text
          - Reply form (if not answered)
          - Existing reply (if answered)
          - Report button
        */}
      </div>

      {/* Empty state */}
      {/* TODO: "Keine Bewertungen" message */}
    </div>
  )
}
