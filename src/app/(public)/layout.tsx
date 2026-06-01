/**
 * (public) Layout
 * 
 * Route Group für öffentliche Seiten
 * - Keine Authentifizierung erforderlich
 * - Sichtbar für alle Besucher (Gäste + eingeloggte Nutzer)
 * - Standardmäßig mit Navbar und Footer
 */

import type { ReactNode } from 'react'

export default function PublicLayout({
  children,
}: {
  children: ReactNode
}) {
  return <>{children}</>
}
