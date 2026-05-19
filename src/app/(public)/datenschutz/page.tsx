/**
 * Datenschutzerklärung
 * 
 * Route: /datenschutz
 * Rendering: SSG
 * 
 * PFLICHT: Vor Go-Live rechtlich prüfen lassen!
 * 
 * Inhalt nach DSGVO:
 * - Verantwortlicher
 * - Datenarten
 * - Rechtsgrundlagen
 * - Betroffenenrechte
 * - Cookies
 * - Drittanbieter
 */

export const metadata = {
  title: 'Datenschutz - Karriko',
  description: 'Datenschutzerklärung von Karriko'
}

export default function PrivacyPage() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-3xl">
      <h1 className="text-4xl font-bold mb-8">Datenschutzerklärung</h1>

      <div className="prose prose-lg max-w-none">
        <h2>1. Verantwortlicher</h2>
        {/* TODO: Data controller information per Art. 13/14 DSGVO */}

        <h2>2. Datenarten und Verarbeitung</h2>
        {/* TODO: Types of personal data collected and purposes */}

        <h2>3. Rechtsgrundlagen</h2>
        {/* TODO: Legal basis per Art. 6 DSGVO */}

        <h2>4. Speicherdauer</h2>
        {/* TODO: Data retention periods */}

        <h2>5. Betroffenenrechte</h2>
        {/* TODO: Rights of data subjects per Art. 15-22 DSGVO */}

        <h2>6. Cookies</h2>
        {/* TODO: Cookie policy and consent management */}

        <h2>7. Drittanbieter</h2>
        {/* TODO: Third-party services (Supabase, Analytics, etc.) */}

        <h2>8. Datenschutzbeauftragter</h2>
        {/* TODO: DPO contact if applicable */}

        <p className="mt-8 pt-8 border-t text-sm text-gray-600">
          ⚠️ <strong>WICHTIG:</strong> Diese Datenschutzerklärung muss vor Go-Live von einem Rechtsanwalt geprüft werden!
        </p>
      </div>
    </div>
  )
}
