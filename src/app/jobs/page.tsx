export default function Jobs() {
  return (
    <div className="bg-slate-50 py-10">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="rounded-[1.5rem] border border-slate-200 bg-white p-8 shadow-sm">
          <div className="mb-8">
            <h1 className="text-3xl font-semibold text-slate-900">Ausbildungsplätze</h1>
            <p className="mt-2 text-sm text-slate-500">Finde deine passende Ausbildung.</p>
          </div>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <div className="rounded-3xl border border-slate-200 bg-slate-50 p-6 shadow-sm">
              <h3 className="text-lg font-semibold text-slate-900">Ausbildungsstelle 1</h3>
              <p className="mt-3 text-sm text-slate-600">Betrieb, Ort</p>
              <button className="mt-6 inline-flex rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800">
                Details
              </button>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-slate-50 p-6 shadow-sm">
              <h3 className="text-lg font-semibold text-slate-900">Ausbildungsstelle 2</h3>
              <p className="mt-3 text-sm text-slate-600">Betrieb, Ort</p>
              <button className="mt-6 inline-flex rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800">
                Details
              </button>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-slate-50 p-6 shadow-sm">
              <h3 className="text-lg font-semibold text-slate-900">Ausbildungsstelle 3</h3>
              <p className="mt-3 text-sm text-slate-600">Betrieb, Ort</p>
              <button className="mt-6 inline-flex rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800">
                Details
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
