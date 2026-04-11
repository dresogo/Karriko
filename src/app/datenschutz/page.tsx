import Link from 'next/link'

export default function DatenschutzPage() {
  return (
    <div className="bg-slate-50 py-10">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="rounded-[1.5rem] border border-slate-200 bg-white p-8 shadow-sm">
          <h1 className="text-3xl font-semibold text-slate-900">Datenschutz</h1>
          <p className="mt-4 text-sm text-slate-500">
            Informationen zur Nutzung und Verarbeitung deiner Daten.
          </p>
          <div className="mt-8 rounded-3xl border border-slate-200 bg-slate-50 p-6 shadow-sm">
            <h2 className="text-xl font-semibold text-slate-900">Hinweis</h2>
            <p className="mt-2 text-sm text-slate-600">Weitere Datenschutzdetails folgen.</p>
            <Link href="/" className="mt-6 inline-flex rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800">
              Zurück zur Startseite
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
