/**
 * Login Seite
 * 
 * Route: /login
 * Rendering: CSR (Client Component)
 * 
 * Login-Methoden:
 * - E-Mail + Passwort
 * - Google OAuth
 * - Apple Sign-in
 * - SMS-OTP
 * 
 * Sicherheit:
 * - Rate Limiting: max. 5 Login-Versuche / Minute / IP
 * - Generische Fehlermeldung bei falschem Passwort
 * - CSRF-Schutz via Supabase Auth
 * - Autocomplete für Passwortmanager
 */

'use client'

import Link from 'next/link'

export default function LoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-md space-y-8">
        {/* Header */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900">Karriko</h1>
          <h2 className="mt-6 text-2xl font-bold text-gray-900">Anmelden</h2>
          <p className="mt-2 text-sm text-gray-600">
            Noch kein Konto?{' '}
            <Link href="/register/azubi" className="font-medium text-emerald-600 hover:text-emerald-500">
              Als Azubi registrieren
            </Link>
            {' / '}
            <Link href="/register/betrieb" className="font-medium text-emerald-600 hover:text-emerald-500">
              Als Betrieb registrieren
            </Link>
          </p>
        </div>

        {/* Login Form */}
        <div className="bg-white py-12 px-6 shadow rounded-lg sm:px-12">
          {/* TODO: Email + Password form with validation */}
          {/* TODO: OAuth buttons (Google, Apple) */}
          {/* TODO: SMS-OTP option */}

          <div className="mt-6">
            <Link href="/forgot-password" className="text-sm font-medium text-emerald-600 hover:text-emerald-500">
              Passwort vergessen?
            </Link>
          </div>
        </div>

        {/* Security Notice */}
        <p className="text-center text-xs text-gray-500">
          Geschützt durch Supabase Auth · SSL-verschlüsselt
        </p>
      </div>
    </div>
  )
}
