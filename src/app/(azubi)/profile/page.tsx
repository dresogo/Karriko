/**
 * Profil Auszubildender
 * 
 * Route: /profile
 * Rendering: SSR (initiale Daten) + CSR (Client-Bearbeitung)
 * 
 * Anzeigefelder:
 * - Profilbild
 * - Vorname, Nachname
 * - E-Mail
 * - Ausbildungsberuf, Ausbildungsjahr
 * - Bundesland
 * - Öffentliches Profil Toggle
 * - Mitglied seit (schreibgeschützt)
 * 
 * DSGVO:
 * - Profilbild-URL in users.avatar_url
 * - Beim Account-Löschen: Avatar aus Storage löschen
 */

export const metadata = {
  title: 'Mein Profil - Karriko',
  description: 'Verwalte dein Profil'
}

export default function AzubiProfilePage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Mein Profil</h1>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Profile Form */}
        <div className="lg:col-span-2">
          <div className="bg-white p-8 rounded-lg shadow space-y-6">
            {/* TODO: Profile form fields */}
            {/* Profile picture upload */}
            {/* First name, Last name */}
            {/* Email with re-verification option */}
            {/* Profession, year, state */}
            {/* Public profile toggle */}
            {/* Submit button */}
          </div>
        </div>

        {/* Preview */}
        <aside className="lg:col-span-1">
          <div className="bg-white p-8 rounded-lg shadow">
            <h3 className="text-lg font-bold mb-4">Vorschau</h3>
            {/* TODO: Profile preview as seen by others */}
          </div>
        </aside>
      </div>
    </div>
  )
}
