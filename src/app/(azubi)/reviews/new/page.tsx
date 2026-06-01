/**
 * Neue Bewertung schreiben
 * 
 * Route: /reviews/new
 * Rendering: CSR (interaktives Multi-Step-Formular)
 * 
 * Voraussetzungen:
 * - Eingeloggt (role = 'AZUBI')
 * - E-Mail verifiziert
 * - Max. 1 Bewertung pro Betrieb pro Nutzer
 * - Rate Limit: max. 3 Bewertungen pro 24h
 * 
 * Formular-Schritte:
 * 1. Betrieb suchen (Autocomplete)
 * 2. Anonymität wählen
 * 3-7. 5 Kategorien mit je 5 Fragen
 * 8. Zusammenfassung + Einwilligung
 * 
 * Kategorien:
 * 1. Arbeitsumfeld & Atmosphäre
 * 2. Ausbildungsqualität
 * 3. Vergütung & Benefits
 * 4. Work-Life-Balance
 * 5. Karriere & Zukunftsperspektiven
 */

'use client'

export default function NewReviewPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Neue Bewertung schreiben</h1>

      <div className="max-w-4xl mx-auto bg-white rounded-lg shadow p-8">
        {/* TODO: Multi-step form with steps indicator */}
        
        {/* Step 1: Company Search */}
        {/* Step 2: Anonymity choice */}
        {/* Steps 3-7: 5 Categories with questions */}
        {/* Step 8: Summary + Consent + Submit */}

        {/* Info boxes */}
        <div className="mt-8 p-4 bg-blue-50 rounded">
          <p className="text-sm text-blue-700">
            💡 Deine Bewertung hilft anderen Auszubildenden und den Betrieben, sich zu verbessern.
          </p>
        </div>
      </div>
    </div>
  )
}
