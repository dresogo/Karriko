/**
 * Registrierung Ausbildungsbetrieb
 * 
 * Route: /register/betrieb
 * Rendering: CSR (Multi-Step-Formular)
 * 
 * Schritte:
 * 1. Unternehmensangaben (Name, Branche, Ort, Website)
 * 2. Ansprechpartner (Name, Funktion, E-Mail, Telefon)
 * 3. Account-Daten (Passwort)
 * 4. Einwilligungen
 * 
 * Nach Registrierung:
 * - E-Mail-Bestätigung
 * - Betriebsprofil wird als verified: false angelegt
 * - Internes Team erhält Benachrichtigung zur Verifizierung
 */

'use client'

import Link from 'next/link'

export default function RegisterBetriebPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900">Karriko</h1>
          <h2 className="mt-6 text-2xl font-bold text-gray-900">Registrierung Betrieb</h2>
          <p className="mt-2 text-sm text-gray-600">
            Bereits registriert?{' '}
            <Link href="/login" className="font-medium text-emerald-600 hover:text-emerald-500">
              Hier anmelden
            </Link>
          </p>
        </div>

        {/* Registration Form */}
        <div className="bg-white py-12 px-6 shadow rounded-lg sm:px-12">
          {/* TODO: Multi-step form */}
          {/* Step 1: Company data */}
          {/* Step 2: Contact person */}
          {/* Step 3: Account data */}
          {/* Step 4: Consents */}

          <div className="mt-6 p-4 bg-blue-50 rounded">
            <p className="text-sm text-blue-700">
              💡 Nach der Registrierung wird Ihr Profil von unserem Team verifiziert. Sie können bereits Ihr Profil bearbeiten und Bewertungen verwalten.
            </p>
          </div>
        </div>

        {/* Links */}
        <div className="text-center text-sm text-gray-600">
          <Link href="/register/azubi" className="font-medium text-emerald-600 hover:text-emerald-500">
            Ich bin Auszubildender
          </Link>
        </div>
      </div>
    </div>
  )
}
