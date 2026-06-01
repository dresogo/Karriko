/**
 * Bewertungsdetailseite
 * 
 * Route: /reviews/[id]
 * Rendering: SSR + ISR
 * 
 * Inhalt:
 * - Vollständige Bewertung mit allen 25 Antworten
 * - Kategorie-Aufschlüsselung
 * - Betriebsantwort (falls vorhanden)
 * - Breadcrumb
 * - "Hilfreich"-Button
 */

export async function generateMetadata({ params }: { params: { id: string } }) {
  // TODO: Fetch review data
  return {
    title: 'Bewertung - Karriko',
    description: 'Vollständige Bewertung eines Ausbildungsbetriebs'
  }
}

export default function ReviewDetailPage({ params }: { params: { id: string } }) {
  return (
    <div className="container mx-auto px-4 py-8">
      {/* Breadcrumb */}
      <nav className="mb-8 text-sm text-gray-600">
        {/* TODO: Breadcrumb navigation */}
      </nav>

      <div className="max-w-4xl mx-auto">
        {/* Review Header */}
        <div className="bg-white p-8 rounded-lg shadow mb-8">
          {/* TODO: Reviewer info, date, overall score */}
          {/* TODO: Company info */}
        </div>

        {/* Review Categories */}
        <div className="space-y-6 mb-8">
          {/* TODO: Category breakdowns with Q&A */}
        </div>

        {/* Company Reply */}
        <div className="bg-blue-50 p-8 rounded-lg mb-8">
          <h3 className="text-lg font-bold mb-4">Antwort des Unternehmens</h3>
          {/* TODO: Company reply text if exists */}
        </div>

        {/* Helpful Button */}
        <div className="flex gap-4">
          {/* TODO: Helpful/Not helpful buttons */}
        </div>
      </div>
    </div>
  )
}
