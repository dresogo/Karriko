import { searchCompanies } from '@/lib/company-search'
import type { CompanySearchResult } from '@/lib/company-search'

export const dynamic = 'force-dynamic'

export default async function SuchePage({
  searchParams,
}: {
  searchParams?: Promise<{
    q?: string
  }>
}) {
  const resolvedSearchParams = (await searchParams) ?? {}
  const query = resolvedSearchParams.q?.trim() ?? ''
  const results: CompanySearchResult[] = await searchCompanies(query, 9)

  return (
    <div className="bg-slate-50 py-10">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="rounded-[1.5rem] border border-slate-200 bg-white p-8 shadow-sm">
          <div className="mb-8">
            <h1 className="text-3xl font-semibold text-slate-900">Suche</h1>
            <p className="mt-2 text-sm text-slate-500">Finde Ausbildungsbetriebe in deiner Nähe.</p>
          </div>

          <form className="rounded-3xl border border-slate-200 bg-slate-50 p-5 shadow-sm" action="/suche" method="get">
            <div className="flex flex-col gap-3 sm:flex-row">
              <input
                type="search"
                name="q"
                defaultValue={query}
                placeholder="Betrieb suchen..."
                className="flex-1 rounded-full border border-slate-200 bg-white px-5 py-3 text-slate-900 shadow-sm outline-none transition focus:border-slate-300 focus:ring-4 focus:ring-slate-200"
              />
              <button className="inline-flex items-center justify-center rounded-full bg-slate-900 px-6 py-3 text-sm font-semibold text-white transition hover:bg-slate-800">
                Suchen
              </button>
            </div>
          </form>

          {query ? (
            <p className="mt-4 text-sm text-slate-500">
              Ergebnisse für <span className="font-medium text-slate-900">{query}</span>
            </p>
          ) : null}

          <div className="mt-10">
            <h2 className="text-lg font-semibold text-slate-900">Suchergebnisse</h2>
            <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {results.map((result) => (
                <div key={result.id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
                  <div className="mb-3 flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.18em] text-emerald-700">
                    <span>{result.industry ?? 'Betrieb'}</span>
                    {result.location ? <span>· {result.location}</span> : null}
                    {result.verified ? <span>· Verifiziert</span> : null}
                  </div>
                  <h3 className="text-lg font-semibold text-slate-900">{result.name}</h3>
                  <p className="mt-2 text-sm text-slate-600">{result.description ?? 'Keine Beschreibung vorhanden.'}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}