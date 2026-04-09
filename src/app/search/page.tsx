export default function Search() {
  return (
    <div className="bg-slate-50 py-10">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="rounded-[1.5rem] border border-slate-200 bg-white p-8 shadow-sm">
          <div className="mb-8">
            <h1 className="text-3xl font-semibold text-slate-900">Suche</h1>
            <p className="mt-2 text-sm text-slate-500">Finde Ausbildungsbetriebe in deiner Nähe.</p>
          </div>

          <div className="rounded-3xl border border-slate-200 bg-slate-50 p-5 shadow-sm">
            <div className="flex flex-col gap-3 sm:flex-row">
              <input
                type="text"
                placeholder="Betrieb suchen..."
                className="flex-1 rounded-full border border-slate-200 bg-white px-5 py-3 text-slate-900 shadow-sm outline-none transition focus:border-slate-300 focus:ring-4 focus:ring-slate-200"
              />
              <button className="inline-flex items-center justify-center rounded-full bg-slate-900 px-6 py-3 text-sm font-semibold text-white transition hover:bg-slate-800">
                Suchen
              </button>
            </div>
          </div>

          <div className="mt-10">
            <h2 className="text-lg font-semibold text-slate-900">Suchergebnisse</h2>
            <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-slate-900">Beispiel Betrieb</h3>
                <p className="mt-2 text-sm text-slate-600">Beschreibung...</p>
              </div>
              <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-slate-900">Beispiel Betrieb</h3>
                <p className="mt-2 text-sm text-slate-600">Beschreibung...</p>
              </div>
              <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
                <h3 className="text-lg font-semibold text-slate-900">Beispiel Betrieb</h3>
                <p className="mt-2 text-sm text-slate-600">Beschreibung...</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
