/**
 * (auth) Layout
 * 
 * Route Group für Authentifizierungsseiten
 * - Keine Authentifizierung erforderlich (nur für nicht eingeloggte Nutzer)
 * - Eingeloggte Nutzer werden zu ihrem Dashboard weitergeleitet
 * - Middleware prüft Session und leitet um wenn nötig
 */

import type { ReactNode } from 'react'

export default function AuthLayout({
  children,
}: {
  children: ReactNode
}) {
  return <>{children}</>
}
