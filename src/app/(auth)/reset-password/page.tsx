/**
 * Passwort zurücksetzen
 * 
 * Route: /reset-password
 * Query-Parameter: ?token=xyz&type=recovery
 * Rendering: CSR
 * 
 * Flow:
 * 1. Token aus URL wird beim Seitenaufruf validiert
 * 2. Ungültiger/abgelaufener Token → Fehlermeldung + Link zu /forgot-password
 * 3. Gültiger Token → Formular: Neues Passwort + Bestätigung
 * 4. Submit → Supabase Auth: updateUser({ password })
 * 5. Weiterleitung zu /login mit Erfolgsmeldung
 * 
 * Sicherheit:
 * - Token ist einmalig verwendbar
 * - Ablaufzeit: 60 Minuten
 * - Nach erfolgreichem Reset: alle aktiven Sessions invalidieren
 */

import { Suspense } from 'react'
import ResetPasswordClient from './reset-password-client'

export default function ResetPasswordPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-gray-50" />}>
      <ResetPasswordClient />
    </Suspense>
  )
}
