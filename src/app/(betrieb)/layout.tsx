/**
 * (betrieb) Layout
 * 
 * Route Group für Ausbildungsbetriebe (eingeloggt)
 * 
 * Auth-Anforderung: role = 'BETRIEB' + E-Mail verifiziert
 * - Azubis werden zu ihrem Dashboard weitergeleitet
 * - Middleware prüft Session + Rolle + gibt Betriebskontext (company_id) weiter
 * - Server Actions und tRPC-Aufrufe nutzen betriebProcedure + Eigentümerprüfung
 * - KRITISCH: Jeder Zugriff auf Bewerbungsunterlagen wird serverseitig an company_id gebunden
 */

import type { ReactNode } from 'react'

export default function BetriebLayout({
  children,
}: Readonly<{
  children: ReactNode
}>) {
  return <>{children}</>
}
