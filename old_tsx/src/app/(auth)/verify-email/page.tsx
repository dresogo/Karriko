/**
 * E-Mail-Verifizierung
 * 
 * Route: /verify-email
 * Query-Parameter: ?token=xyz&type=signup|email_change
 * Rendering: SSR (Token-Verarbeitung server-seitig)
 * 
 * Flow:
 * 1. Nutzer klickt Link in der Bestätigungs-E-Mail
 * 2. Server verarbeitet Token via Supabase Auth
 * 3. Erfolg → Weiterleitung zu /dashboard mit Willkommens-Toast
 * 4. Fehler (Token abgelaufen) → Fehlermeldung + "E-Mail erneut senden"-Button
 * 
 * Sonderfälle:
 * - Token abgelaufen: Resend-Button sendet neue Bestätigungs-E-Mail
 * - E-Mail-Änderung: Neue E-Mail muss bestätigt werden
 * - Unverifizierte Accounts können lesen, aber keine Bewertungen schreiben
 */

import { Suspense } from 'react'

export const metadata = {
  title: 'E-Mail verifizieren - Karriko',
  description: 'Verifiziere deine E-Mail-Adresse'
}

export default function VerifyEmailPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900">Karriko</h1>
          <h2 className="mt-6 text-2xl font-bold text-gray-900">E-Mail verifizieren</h2>
        </div>

        {/* Content */}
        <div className="bg-white py-12 px-6 shadow rounded-lg sm:px-12">
          <Suspense fallback={<div className="text-center text-gray-600">Verifizierung läuft...</div>}>
            {/* TODO: Token processing */}
            {/* TODO: Success message or error message with resend button */}
          </Suspense>
        </div>

        {/* Info */}
        <div className="text-center text-sm text-gray-600">
          <p>
            Die E-Mail sollte in wenigen Minuten ankommen. Bitte überprüfe auch deinen Spam-Ordner.
          </p>
        </div>
      </div>
    </div>
  )
}
