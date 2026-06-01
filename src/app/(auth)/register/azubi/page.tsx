/**
 * Registrierung Auszubildende
 * 
 * Route: /register/azubi
 * Rendering: CSR (Multi-Step-Formular)
 * 
 * Schritte:
 * 1. Persönliche Daten (Vorname, Nachname, E-Mail, Passwort)
 * 2. Ausbildungsinfo (optional)
 * 3. Einwilligungen (Datenschutz, AGB, Newsletter)
 * 
 * Nach Registrierung:
 * - Supabase Auth sendet Bestätigungs-E-Mail
 * - Weiterleitung zu /verify-email?type=registration
 */

'use client'

import Link from 'next/link'

export default function RegisterAzubiPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900">Karriko</h1>
          <h2 className="mt-6 text-2xl font-bold text-gray-900">Registrierung Azubi</h2>
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
          {/* Step 1: Personal data */}
          {/* Step 2: Training info (optional) */}
          {/* Step 3: Consents */}
          
          {/* TODO: Password strength indicator */}
          {/* TODO: Validation messages */}
        </div>

        {/* Links */}
        <div className="text-center text-sm text-gray-600">
          <Link href="/register/betrieb" className="font-medium text-emerald-600 hover:text-emerald-500">
            Ich bin Ausbildungsbetrieb
          </Link>
        </div>
      </div>
    </div>
  )
}
