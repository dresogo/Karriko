/**
 * Kontaktseite
 * 
 * Route: /kontakt
 * Rendering: SSR
 * 
 * Inhalt:
 * - Kontaktformular: Name, E-Mail, Betreff, Nachricht, Datenschutz-Checkbox
 * - Kontaktdaten
 */

export const metadata = {
  title: 'Kontakt - Karriko',
  description: 'Kontaktieren Sie uns'
}

export default function ContactPage() {
  return (
    <div className="container mx-auto px-4 py-12">
      <h1 className="text-4xl font-bold text-center mb-12">Kontakt</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-12 max-w-4xl mx-auto">
        {/* Contact Form */}
        <div>
          <h2 className="text-2xl font-bold mb-6">Schreiben Sie uns</h2>
          {/* TODO: Contact form with Zod validation */}
          {/* Fields: name, email, subject, message, consent checkbox */}
        </div>

        {/* Contact Info */}
        <div>
          <h2 className="text-2xl font-bold mb-6">Weitere Informationen</h2>
          {/* TODO: Company address, email, phone */}
          {/* TODO: Social links */}
        </div>
      </div>
    </div>
  )
}
