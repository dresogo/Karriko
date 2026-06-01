/**
 * Unternehmensseite
 * 
 * Route: /company/[slug]
 * Rendering: SSR + ISR (revalidate: 60s)
 * 
 * Sektionen:
 * - Header (Headerbild, Logo, Name, Branche, Ort)
 * - Score-Übersicht
 * - Bewertungs-Feed
 * - Stellenanzeigen
 * - Profil-Info
 * - CTA (Bewertung schreiben)
 */

import { notFound } from 'next/navigation'

export async function generateMetadata({ params }: { params: { slug: string } }) {
  // TODO: Fetch company data via tRPC
  return {
    title: `Unternehmen - Karriko`,
    description: 'Unternehmensprofile und Bewertungen'
  }
}

export default function CompanyPage({ params }: { params: { slug: string } }) {
  return (
    <div className="space-y-8">
      {/* Company Header */}
      <div className="bg-gradient-to-r from-emerald-500 to-emerald-600 h-64">
        {/* TODO: Header image, logo, company info */}
      </div>

      <div className="container mx-auto px-4">
        {/* Score Overview */}
        <section className="mb-12">
          <h2 className="text-2xl font-bold mb-4">Bewertungen</h2>
          {/* TODO: Score cards, category bars */}
        </section>

        {/* Reviews Feed */}
        <section className="mb-12">
          <h3 className="text-2xl font-bold mb-4">Alle Bewertungen</h3>
          {/* TODO: Review list with sorting */}
        </section>

        {/* Job Listings */}
        <section className="mb-12">
          <h3 className="text-2xl font-bold mb-4">Offene Ausbildungsplätze</h3>
          {/* TODO: Job cards */}
        </section>

        {/* Company Description */}
        <section>
          <h3 className="text-2xl font-bold mb-4">Über das Unternehmen</h3>
          {/* TODO: Description, website, social links */}
        </section>
      </div>
    </div>
  )
}
