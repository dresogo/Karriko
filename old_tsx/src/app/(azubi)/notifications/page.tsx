/**
 * Benachrichtigungen
 * 
 * Route: /notifications
 * Rendering: SSR + Realtime (Supabase Realtime Subscription)
 * 
 * Benachrichtigungstypen:
 * - REVIEW_REPLY: Betrieb antwortet auf Bewertung
 * - REVIEW_FLAGGED: Bewertung wurde gemeldet
 * - REVIEW_REMOVED: Admin entfernt Bewertung
 * - SYSTEM: Plattform-Meldungen
 * 
 * Funktionen:
 * - Als gelesen markieren (einzeln + alle)
 * - Notification-Badge im Header zeigt ungelesene Anzahl
 */

export const metadata = {
  title: 'Benachrichtigungen - Karriko',
  description: 'Deine Benachrichtigungen'
}

export default function NotificationsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold">Benachrichtigungen</h1>
        {/* TODO: Mark all as read button */}
      </div>

      {/* Notifications List */}
      <div className="space-y-4 max-w-2xl">
        {/* TODO: Notification items with:
          - Icon based on type
          - Title + message
          - Date/time
          - "Mark as read" button
          - Link to related content
        */}
      </div>

      {/* Empty state */}
      {/* TODO: "Keine neuen Benachrichtigungen" message */}
    </div>
  )
}
