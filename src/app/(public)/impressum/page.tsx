/**
 * Impressum
 * 
 * Route: /impressum
 * Rendering: SSG
 * 
 * Inhalt nach § 5 TMG:
 * - Verantwortlicher
 * - Anschrift
 * - E-Mail
 * - USt-ID
 */

export const metadata = {
  title: 'Impressum - Karriko',
  description: 'Impressum von Karriko'
}

export default function ImpressumPage() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-3xl">
      <h1 className="text-4xl font-bold mb-8">Impressum</h1>

      <div className="prose prose-lg max-w-none">
        <h2>Angaben gemäß § 5 TMG</h2>
        
        <h3>Verantwortlicher</h3>
        {/* TODO: Company name, address, email, phone, registration details */}

        <h3>USt-ID</h3>
        {/* TODO: VAT ID if applicable */}

        <h3>Vertreter</h3>
        {/* TODO: Legal representatives if applicable */}

        <h3>Kontakt</h3>
        {/* TODO: Contact information */}

        <h3>Streitschlichtung</h3>
        {/* TODO: Legal notice about dispute resolution */}
      </div>
    </div>
  )
}
