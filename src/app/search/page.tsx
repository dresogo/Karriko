export default function Search() {
  return (
    <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
      <div className="px-4 py-6 sm:px-0">
        <h1 className="text-3xl font-bold text-gray-900">Suche</h1>
        <p className="mt-2 text-sm text-gray-600">
          Finde Ausbildungsbetriebe in deiner Nähe.
        </p>
      </div>
      <div className="bg-white overflow-hidden shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <div className="flex">
            <input
              type="text"
              placeholder="Betrieb suchen..."
              className="flex-1 rounded-l-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
            />
            <button className="bg-primary-600 hover:bg-primary-700 text-white px-4 py-2 rounded-r-md">
              Suchen
            </button>
          </div>
        </div>
      </div>
      <div className="mt-8">
        <h2 className="text-lg font-medium text-gray-900">Suchergebnisse</h2>
        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {/* Placeholder für Suchergebnisse */}
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="p-6">
              <h3 className="text-lg font-medium text-gray-900">Beispiel Betrieb</h3>
              <p className="mt-2 text-sm text-gray-600">Beschreibung...</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}