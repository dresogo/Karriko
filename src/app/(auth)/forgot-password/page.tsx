/**
 * Passwort vergessen
 * 
 * Route: /forgot-password
 * Rendering: CSR
 * 
 * Flow:
 * 1. Nutzer gibt E-Mail ein
 * 2. POST → Supabase Auth: sendPasswordResetEmail()
 * 3. Immer gleiche Erfolgsmeldung (verhindert Account-Enumeration)
 * 4. E-Mail enthält Link mit Token (gültig 60 Minuten)
 */

'use client'

export default function ForgotPasswordPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900">Karriko</h1>
          <h2 className="mt-6 text-2xl font-bold text-gray-900">Passwort zurücksetzen</h2>
          <p className="mt-2 text-sm text-gray-600">
            Gib deine E-Mail-Adresse ein und wir senden dir einen Link zum Zurücksetzen deines Passworts.
          </p>
        </div>

        {/* Form */}
        <div className="bg-white py-12 px-6 shadow rounded-lg sm:px-12">
          {/* TODO: Email input form */}
          {/* TODO: Submit button */}
        </div>

        {/* Messages */}
        <div className="text-center text-sm text-gray-600">
          <p className="mb-4">
            Falls ein Konto mit dieser E-Mail-Adresse existiert, wird ein Zurücksetzen-Link versendet.
          </p>
          <a href="/login" className="font-medium text-emerald-600 hover:text-emerald-500">
            Zurück zum Login
          </a>
        </div>
      </div>
    </div>
  )
}
