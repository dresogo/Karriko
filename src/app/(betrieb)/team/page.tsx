/**
 * Team / Ansprechpartner verwalten
 * 
 * Route: /team
 * Rendering: SSR
 * 
 * Felder pro Ansprechpartner:
 * - Name, Rolle, E-Mail, Telefon, Profilbild
 * - Public-Toggles für E-Mail und Telefon
 * 
 * DSGVO-Hinweis:
 * - E-Mail/Telefon nur angezeigt wenn isPublic = true
 * - Ansprechpartner können jederzeit entfernt werden
 */

export const metadata = {
  title: 'Team - Karriko Betrieb',
  description: 'Verwalte dein Team'
}

export default function BetriebTeamPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold">Ansprechpartner</h1>
        {/* TODO: Add team member button */}
      </div>

      {/* Team Members List */}
      <div className="space-y-4">
        {/* TODO: Team member cards/list with:
          - Profile image
          - Name
          - Role
          - Email (if public)
          - Phone (if public)
          - Edit button
          - Delete button
        */}
      </div>

      {/* Empty state */}
      {/* TODO: "Keine Ansprechpartner hinzugefügt" message */}

      {/* DSGVO Notice */}
      <div className="mt-8 p-4 bg-blue-50 rounded text-sm text-blue-700">
        🔒 E-Mail und Telefon werden nur angezeigt, wenn diese Optionen aktiviert sind. 
        Ansprechpartner können ihre Einträge jederzeit entfernen lassen.
      </div>
    </div>
  )
}
