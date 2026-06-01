/**
 * Allgemeine Geschäftsbedingungen (AGB)
 * 
 * Route: /agb
 * Rendering: SSG
 * 
 * PFLICHT: Vor Go-Live rechtlich prüfen lassen!
 */

export const metadata = {
  title: 'AGB - Karriko',
  description: 'Allgemeine Geschäftsbedingungen von Karriko'
}

export default function TermsPage() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-3xl">
      <h1 className="text-4xl font-bold mb-8">Allgemeine Geschäftsbedingungen</h1>

      <div className="prose prose-lg max-w-none">
        <h2>1. Geltungsbereich</h2>
        {/* TODO: Scope of terms */}

        <h2>2. Vertragsgegenstand</h2>
        {/* TODO: Services provided */}

        <h2>3. Registrierung und Nutzerkonto</h2>
        {/* TODO: Registration requirements */}

        <h2>4. Nutzerverhalten und Inhalte</h2>
        {/* TODO: User obligations and content policies */}

        <h2>5. Bewertungen</h2>
        {/* TODO: Rules for reviews and ratings */}

        <h2>6. Freistellung und Haftung</h2>
        {/* TODO: Liability and indemnification */}

        <h2>7. Freemium und Premium Services</h2>
        {/* TODO: Free vs Premium terms */}

        <h2>8. Kündigung und Sperrung</h2>
        {/* TODO: Account deletion, suspension, termination */}

        <h2>9. Änderungen der AGB</h2>
        {/* TODO: Terms of modification */}

        <h2>10. Schlussbestimmungen</h2>
        {/* TODO: Final provisions, applicable law */}

        <p className="mt-8 pt-8 border-t text-sm text-gray-600">
          ⚠️ <strong>WICHTIG:</strong> Diese AGB müssen vor Go-Live von einem Rechtsanwalt geprüft werden!
        </p>
      </div>
    </div>
  )
}
