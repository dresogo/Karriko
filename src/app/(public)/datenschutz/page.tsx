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
        <p>
          Hier gehört die vollständige Angabe des Verantwortlichen hinein, inklusive Name, Anschrift, E-Mail-Adresse und gegebenenfalls weiterer Kontaktinformationen.
        </p>

        <h2>2. Datenarten und Verarbeitung</h2>
        <p>
          Beschreibe hier, welche personenbezogenen Daten erhoben werden und zu welchen Zwecken sie verarbeitet werden.
        </p>

        <h2>3. Rechtsgrundlagen</h2>
        <p>
          Ergänze hier die jeweiligen Rechtsgrundlagen nach Art. 6 DSGVO für Registrierung, Nutzung, Support, Sicherheit und Analyse.
        </p>

        <h2>4. Speicherdauer</h2>
        <p>
          Definiere hier, wie lange Daten gespeichert werden und nach welchen Kriterien eine Löschung oder Anonymisierung erfolgt.
        </p>

        <h2>5. Betroffenenrechte</h2>
        <p>
          Nenne hier die Rechte auf Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit und Widerspruch.
        </p>

        <h2>6. Cookies</h2>
        <p>
          Erkläre hier den Einsatz von Cookies, Session-Speichern und etwaigen Consent-Mechanismen.
        </p>

        <h2>7. Drittanbieter</h2>
        <p>
          Liste hier externe Dienste wie Hosting, Authentifizierung, Speicher, Analyse oder E-Mail-Provider auf.
        </p>

        <h2>8. Datenschutzbeauftragter</h2>
        <p>
          Falls ein Datenschutzbeauftragter erforderlich ist, trage hier dessen Kontaktdaten ein.
        </p>

        <p className="mt-8 pt-8 border-t text-sm text-gray-600">
          ⚠️ <strong>WICHTIG:</strong> Diese Datenschutzerklärung muss vor Go-Live von einem Rechtsanwalt geprüft werden!
        </p>
      </div>
    </div>
  )
}
