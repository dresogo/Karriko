'use client'

import Link from 'next/link'
import { useState } from 'react'
import JobCard, { type JobListing } from '@/components/JobCard'
import ReviewCard, { type Review } from '@/components/ReviewCard'

const JOB_LISTINGS: JobListing[] = [
  {
    id: 1,
    title: 'Fachinformatiker (m/w/d)',
    company: 'TechSolutions GmbH',
    location: 'München',
    badge: 'Vor 2 Tagen',
    badgeVariant: 'days',
    icon: '💻',
    iconBg: '#1a3a2a',
  },
  {
    id: 2,
    title: 'Industriekaufmann (m/w/d)',
    company: 'Global Logistics AG',
    location: 'Hamburg',
    badge: 'Vor 4 Tagen',
    badgeVariant: 'days',
    icon: '📦',
    iconBg: '#c8b89a',
  },
  {
    id: 3,
    title: 'Mediengestalter (m/w/d)',
    company: 'Creative Pulse Media',
    location: 'Berlin',
    badge: 'Gestern',
    badgeVariant: 'recent',
    icon: '🎨',
    iconBg: '#e8d5b0',
  },
  {
    id: 4,
    title: 'Mechatroniker (m/w/d)',
    company: 'AutoTech Solutions',
    location: 'Stuttgart',
    badge: 'Neu',
    badgeVariant: 'new',
    icon: '⚙️',
    iconBg: '#1a3a2a',
  },
]

const REVIEWS: Review[] = [
  {
    id: 1,
    author: 'Anonym',
    rating: 5,
    text: 'Super Einarbeitung und tolles Team. Man darf von Anfang an Verantwortung übernehmen.',
    isAnonymous: true,
  },
  {
    id: 2,
    author: 'Lukas M.',
    rating: 4,
    text: 'Die Vergütung ist top, aber die Arbeitszeiten sind manchmal etwas lang.',
    isAnonymous: false,
  },
  {
    id: 3,
    author: 'Sarah K.',
    rating: 5,
    text: 'Beste Entscheidung meines Lebens. Die Projekte sind abwechslungsreich und modern.',
    isAnonymous: false,
  },
  {
    id: 4,
    author: 'Anonym',
    rating: 3,
    text: 'Solide Ausbildung, aber die digitale Ausstattung könnte besser sein.',
    isAnonymous: true,
  },
  {
    id: 5,
    author: 'Jonas W.',
    rating: 4,
    text: 'Sehr familiäre Atmosphäre. Hier wird man als Mensch geschätzt, nicht nur als Azubi.',
    isAnonymous: false,
  },
  {
    id: 6,
    author: 'Elena R.',
    rating: 3,
    text: 'Gute Struktur, aber die Lerninhalte sind teilweise etwas veraltet.',
    isAnonymous: false,
  },
]

const POPULAR_SEARCHES = ['Informatik', 'Berlin', 'Nachhaltigkeit']

export default function Home() {
  const [searchValue, setSearchValue] = useState('')

  return (
    <div className="font-sans bg-gradient-to-b from-[#eef2ee] via-[#f4f6f4] to-white">
      {/* ── Hero ── */}
      <section className="px-8 py-20 md:py-32 text-center">
        <div className="mx-auto max-w-2xl">
          <h1 className="font-serif-display text-5xl md:text-6xl text-[#0d1f16] leading-tight mb-6">
            Der transparente Kompass für deine Karriere.
          </h1>
          <p className="text-base text-[#4b5563] leading-relaxed mb-10">
            Finde Ausbildungsplätze, die wirklich zu dir passen. Basierend auf echten Erfahrungen und kuratierten Daten.
          </p>

          {/* Search bar */}
          <div className="flex items-center bg-white rounded-2xl p-2 border border-[#e5e7eb] shadow-lg gap-2 max-w-md mx-auto mb-6">
            <span className="text-xl text-[#9ca3af] px-4">🔍</span>
            <input
              type="text"
              placeholder="Suche nach Unternehmen, Stadt oder Branche"
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              className="flex-1 border-none bg-transparent text-sm text-[#111827] placeholder:text-[#9ca3af] outline-none"
            />
            <button className="karriko-btn-primary">Suchen</button>
          </div>

          {/* Popular searches */}
          <div className="flex items-center justify-center gap-2 flex-wrap">
            <span className="text-xs text-[#9ca3af]">Beliebte Suchen:</span>
            {POPULAR_SEARCHES.map((tag) => (
              <button
                key={tag}
                className="karriko-badge"
                onClick={() => setSearchValue(tag)}
              >
                {tag}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* ── Aktuelle Ausbildungsplätze ── */}
      <section className="px-8 py-20">
        <div className="mx-auto max-w-7xl">
          <div className="flex flex-col md:flex-row md:items-end md:justify-between gap-6 mb-10">
            <div>
              <h2 className="font-serif-display text-3xl text-[#111827] mb-1">
                Aktuelle Ausbildungsplätze
              </h2>
              <p className="text-xs text-[#9ca3af]">
                Die neuesten Einstiegsmöglichkeiten für dich.
              </p>
            </div>
            <Link
              href="/jobs"
              className="text-xs font-semibold text-[#1a3a2a] flex items-center gap-1 transition hover:gap-2"
            >
              Alle Jobs ansehen →
            </Link>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
            {JOB_LISTINGS.map((job) => (
              <JobCard key={job.id} job={job} />
            ))}
          </div>
        </div>
      </section>

      {/* ── Neueste Bewertungen ── */}
      <section className="px-8 py-20 border-y border-[#e5e7eb] bg-[#f9fafb]">
        <div className="mx-auto max-w-7xl">
          <div className="text-center mb-12">
            <h2 className="font-serif-display text-4xl text-[#111827] mb-2">
              Neueste Bewertungen
            </h2>
            <p className="text-sm text-[#9ca3af]">
              Ehrliche Einblicke von Azubis für Azubis. Ohne Filter.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {REVIEWS.map((review) => (
              <ReviewCard key={review.id} review={review} />
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}
