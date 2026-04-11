'use client'

import Link from 'next/link'
import { useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faMagnifyingGlass, faXmark } from '@fortawesome/free-solid-svg-icons'
import JobCard, { type JobListing } from '@/components/JobCard'

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

const POPULAR_SEARCHES = ['Informatik', 'Berlin', 'Nachhaltigkeit']

const SEO_POSTS = [
  {
    id: 1,
    title: 'SEO für Azubi-Websites: Die besten Einstiegstipps',
    excerpt: 'Wie kleine Ausbildungsseiten mit gezielten Keywords und lokalem Content mehr Sichtbarkeit gewinnen.',
    date: '12. April 2026',
    tag: 'SEO Basics',
  },
  {
    id: 2,
    title: 'Content-Struktur für Ausbildungsplätze',
    excerpt: 'So baust du deine Stellenbeschreibung und Arbeitgeberseite SEO-freundlich auf.',
    date: '8. April 2026',
    tag: 'Content',
  },
  {
    id: 3,
    title: 'Local SEO: Azubis in deiner Stadt finden',
    excerpt: 'Mit lokalem Fokus erreichst du Bewerber in der Nähe – von Google My Business bis Stadtseiten.',
    date: '3. April 2026',
    tag: 'Local SEO',
  },
]

export default function Home() {
  const router = useRouter()
  const [searchValue, setSearchValue] = useState('')

  const handleSearch = (query: string = searchValue) => {
    const trimmedQuery = query.trim()
    if (!trimmedQuery) return

    setSearchValue(trimmedQuery)
    router.push(`/search?q=${encodeURIComponent(trimmedQuery)}`)
  }

  const searchSuggestions = useMemo(() => {
    const query = searchValue.trim().toLowerCase()
    if (!query) return []

    const sourceSuggestions = [
      ...POPULAR_SEARCHES,
      ...JOB_LISTINGS.flatMap((job) => [job.title, job.company, job.location]),
    ]

    return Array.from(new Set(sourceSuggestions))
      .filter((item) => item.toLowerCase().includes(query))
      .slice(0, 6)
  }, [searchValue])

  return (
    <div className="font-sans bg-gradient-to-b from-[#eef2ee] via-[#f4f6f4] to-white scroll-smooth snap-y snap-mandatory overflow-x-hidden">
      {/* ── Hero ── */}
      <section className="snap-start flex flex-col justify-center items-center px-8 py-20 md:py-32 text-center border-b border-[#e5e7eb]">
        <div className="w-full max-w-2xl">
          <h1 className="font-serif-display text-5xl md:text-6xl text-[#0d1f16] leading-tight mb-6">
            Der transparente Kompass für deine Karriere.
          </h1>
          <p className="text-base text-[#4b5563] leading-relaxed mb-10">
            Finde Ausbildungsplätze, die wirklich zu dir passen. Basierend auf echten Erfahrungen und kuratierten Daten.
          </p>

          {/* Search bar */}
          <div className="relative max-w-2xl mx-auto mb-6">
            <form
              onSubmit={(event) => {
                event.preventDefault()
                handleSearch()
              }}
              className="flex flex-col"
            >
              <div className="flex items-center bg-white rounded-2xl p-2 border border-[#e5e7eb] shadow-lg gap-2">
                <span className="text-xl text-[#9ca3af] px-4">
                  <FontAwesomeIcon icon={faMagnifyingGlass} />
                </span>
                <input
                  type="text"
                  placeholder="Suche nach Unternehmen, Stadt oder Branche"
                  value={searchValue}
                  onChange={(e) => setSearchValue(e.target.value)}
                  className="flex-1 border-none bg-transparent text-sm text-[#111827] placeholder:text-[#9ca3af] outline-none"
                />
                <button
                  type="button"
                  onClick={() => setSearchValue('')}
                  aria-label="Suchfeld leeren"
                  className="inline-flex items-center justify-center rounded-full p-2 text-[#6b7280] hover:bg-[#f5f5f5] transition"
                >
                  <FontAwesomeIcon icon={faXmark} className="text-lg" />
                </button>
                <button type="submit" className="karriko-btn-primary">
                  Suchen
                </button>
              </div>

              {searchSuggestions.length > 0 && (
                <div className="absolute left-0 right-0 top-full mt-2 rounded-2xl bg-white border border-[#e5e7eb] shadow-lg overflow-hidden z-10">
                  {searchSuggestions.map((suggestion) => (
                    <button
                      key={suggestion}
                      type="button"
                      onClick={() => handleSearch(suggestion)}
                      className="w-full text-left px-4 py-3 text-sm text-[#111827] hover:bg-[#f5f5f5] transition"
                    >
                      {suggestion}
                    </button>
                  ))}
                </div>
              )}
            </form>
          </div>

          {/* Popular searches */}
          <div className="flex items-center justify-center gap-2 flex-wrap">
            <span className="text-xs text-[#9ca3af]">Beliebte Suchen:</span>
            {POPULAR_SEARCHES.map((tag) => (
              <button
                key={tag}
                type="button"
                className="karriko-badge"
                onClick={() => handleSearch(tag)}
              >
                {tag}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* ── Aktuelle Ausbildungsplätze ── */}
      <section className="snap-start flex flex-col justify-center items-center px-8 py-20">
        <div className="w-full max-w-7xl">
          <div className="flex flex-col items-center md:flex-row md:items-end md:justify-between gap-6 mb-10">
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

      {/* ── Neueste SEO Blog-Beiträge ── */}
      <section className="snap-start flex flex-col justify-center items-center px-8 py-20 border-y border-[#e5e7eb] bg-[#f9fafb]">
        <div className="w-full max-w-7xl">
          <div className="text-center mb-12">
            <h2 className="font-serif-display text-4xl text-[#111827] mb-2">
              Neueste SEO Blog-Beiträge
            </h2>
            <p className="text-sm text-[#9ca3af] max-w-2xl mx-auto">
              Die aktuellsten Artikel mit Praxis-Tipps für bessere Sichtbarkeit deiner Ausbildungsseiten.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {SEO_POSTS.map((post) => (
              <article key={post.id} className="rounded-3xl border border-[#e5e7eb] bg-white p-6 shadow-sm hover:shadow-md transition">
                <div className="mb-4 inline-flex rounded-full bg-[#e8f7f0] px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-[#1a3a2a]">
                  {post.tag}
                </div>
                <h3 className="mb-3 text-2xl font-semibold text-[#111827] leading-tight">
                  {post.title}
                </h3>
                <p className="mb-5 text-sm text-[#4b5563] leading-relaxed">
                  {post.excerpt}
                </p>
                <p className="text-xs text-[#9ca3af]">{post.date}</p>
              </article>
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}
