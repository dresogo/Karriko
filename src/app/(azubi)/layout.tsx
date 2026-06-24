/**
 * (azubi) Layout
 * 
 * Route Group für Auszubildende (eingeloggt)
 * 
 * Auth-Anforderung: role = 'AZUBI' + E-Mail verifiziert
 * - Betriebe werden zu ihrer Dashboard-Seite weitergeleitet
 * - Middleware prüft Session + Rolle bei jedem Seitenaufruf
 * - Server Actions und tRPC-Aufrufe nutzen azubiProcedure
 */

import type { ReactNode } from 'react'

export default function AzubiLayout({
  children,
}: Readonly<{
  children: ReactNode
}>) {
  return <>{children}</>
}
